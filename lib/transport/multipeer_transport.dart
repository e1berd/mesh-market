import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:pm_offline/pm_offline.dart';

import 'messages.dart';
import 'peer_link.dart';

class MultipeerIncomingLink {
  MultipeerIncomingLink({
    required this.peerId,
    required this.folderId,
    required this.link,
  });

  final String peerId;
  final String folderId;
  final PeerLink link;
}

class MultipeerTransport {
  MultipeerTransport({required this.deviceId});

  final String deviceId;

  final _channel = const MultipeerChannel();
  final _incoming = StreamController<MultipeerIncomingLink>.broadcast();
  final _links = <String, _MultipeerLink>{};
  final _pending = <String, Completer<PeerLink>>{};
  StreamSubscription<MultipeerEvent>? _events;
  bool _started = false;

  Stream<MultipeerIncomingLink> get incoming => _incoming.stream;

  static Future<bool> isSupported() async {
    if (!Platform.isIOS && !Platform.isMacOS) return false;
    return const MultipeerChannel().isSupported();
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _events = _channel.events.listen(_onEvent);
    await _channel.start(deviceId: deviceId);
  }

  Future<PeerLink> open({
    required String peerId,
    required String folderId,
  }) async {
    await start();
    final sessionId = await _channel.open(peerId: peerId, folderId: folderId);
    if (sessionId == null || sessionId.isEmpty) {
      throw StateError('multipeer: open failed');
    }
    final completer = Completer<PeerLink>();
    _pending[sessionId] = completer;
    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        _pending.remove(sessionId);
        throw StateError('multipeer: connect timeout');
      },
    );
  }

  void _onEvent(MultipeerEvent event) {
    switch (event.type) {
      case 'connected':
        _pending.remove(event.sessionId)?.complete(_registerLink(event));
      case 'incoming':
        final link = _registerLink(event);
        _incoming.add(
          MultipeerIncomingLink(
            peerId: event.peerId ?? '',
            folderId: event.folderId ?? '',
            link: link,
          ),
        );
      case 'data':
        final data = event.data;
        if (data != null) _links[event.sessionId]?.addData(data);
      case 'closed':
        _links.remove(event.sessionId)?.closeIncoming();
        _pending
            .remove(event.sessionId)
            ?.completeError(StateError('multipeer: closed'));
    }
  }

  _MultipeerLink _registerLink(MultipeerEvent event) => _links.putIfAbsent(
    event.sessionId,
    () => _MultipeerLink(
      sessionId: event.sessionId,
      peerId: event.peerId ?? '',
      channel: _channel,
    ),
  );

  Future<void> stop() async {
    if (!_started) return;
    _started = false;
    await _events?.cancel();
    for (final link in [..._links.values]) {
      await link.closeIncoming();
    }
    _links.clear();
    await _channel.stop();
  }
}

class _MultipeerLink implements PeerLink {
  _MultipeerLink({
    required this.sessionId,
    required this.peerId,
    required this.channel,
  });

  final String sessionId;
  final MultipeerChannel channel;

  @override
  final String peerId;

  final _incoming = StreamController<SyncMessage>();

  @override
  Stream<SyncMessage> get incoming => _incoming.stream;

  void addData(Uint8List data) {
    if (!_incoming.isClosed) _incoming.add(SyncMessage.decode(data));
  }

  @override
  Future<void> send(SyncMessage message) =>
      channel.send(sessionId: sessionId, data: message.encode());

  @override
  Future<void> close() async {
    await channel.closeSession(sessionId);
    await closeIncoming();
  }

  Future<void> closeIncoming() async {
    if (!_incoming.isClosed) await _incoming.close();
  }
}
