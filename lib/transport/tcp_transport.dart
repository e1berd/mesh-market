import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'messages.dart';
import 'peer_link.dart';

class DirectTcpIncomingLink {
  const DirectTcpIncomingLink({
    required this.peerId,
    required this.folderId,
    required this.link,
  });

  final String peerId;
  final String folderId;
  final PeerLink link;
}

class DirectTcpTransport {
  DirectTcpTransport({required this.deviceId});

  final String deviceId;
  final _incoming = StreamController<DirectTcpIncomingLink>.broadcast();

  ServerSocket? _server;

  int get boundPort => _server?.port ?? 0;

  Stream<DirectTcpIncomingLink> get incoming => _incoming.stream;

  Future<void> start() async {
    if (_server != null) return;
    final server = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    server.listen(_accept, onError: (_) {});
    _server = server;
  }

  Future<PeerLink> open({
    required InternetAddress address,
    required int port,
    required String peerId,
    required String folderId,
  }) async {
    final socket = await Socket.connect(
      address,
      port,
      timeout: const Duration(seconds: 8),
    );
    final link = TcpPeerLink(peerId: peerId, socket: socket);
    await link.send(OpenLink(deviceId, folderId));
    return link;
  }

  void _accept(Socket socket) {
    unawaited(() async {
      final link = TcpPeerLink(peerId: 'pending', socket: socket);
      try {
        final open = await link.incoming
            .where((message) => message is OpenLink)
            .cast<OpenLink>()
            .first
            .timeout(const Duration(seconds: 8));
        _incoming.add(
          DirectTcpIncomingLink(
            peerId: open.deviceId,
            folderId: open.folderId,
            link: link,
          ),
        );
      } on Object {
        await link.close();
      }
    }());
  }

  Future<void> stop() async {
    await _server?.close();
    _server = null;
    await _incoming.close();
  }
}

class TcpPeerLink implements PeerLink {
  TcpPeerLink({required this.peerId, required this._socket}) {
    _subscription = _socket.listen(
      (chunk) => _reader.add(Uint8List.fromList(chunk)),
      onError: (_) => closeIncoming(),
      onDone: closeIncoming,
      cancelOnError: true,
    );
    _reader.messages.listen(
      _incoming.add,
      onError: _incoming.addError,
      onDone: closeIncoming,
    );
  }

  @override
  final String peerId;

  final Socket _socket;
  final _incoming = StreamController<SyncMessage>.broadcast();
  final _reader = _TcpFrameReader();
  late final StreamSubscription<List<int>> _subscription;
  Future<void> _sendQueue = Future.value();

  @override
  Stream<SyncMessage> get incoming => _incoming.stream;

  @override
  Future<void> send(SyncMessage message) {
    final encoded = message.encode();
    final result = _sendQueue.then((_) async {
      final header = ByteData(4)..setUint32(0, encoded.length);
      _socket.add(header.buffer.asUint8List());
      _socket.add(encoded);
      await _socket.flush();
    });
    _sendQueue = result.catchError((Object _) {});
    return result;
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await _socket.close();
    await closeIncoming();
  }

  Future<void> closeIncoming() async {
    if (!_incoming.isClosed) await _incoming.close();
  }
}

class _TcpFrameReader {
  final _messages = StreamController<SyncMessage>();
  final _buffer = BytesBuilder(copy: false);

  Stream<SyncMessage> get messages => _messages.stream;

  void add(Uint8List chunk) {
    _buffer.add(chunk);
    _drain();
  }

  void _drain() {
    var bytes = _buffer.takeBytes();
    while (bytes.length >= 4) {
      final length = ByteData.sublistView(bytes, 0, 4).getUint32(0);
      if (bytes.length < 4 + length) break;
      final payload = bytes.sublist(4, 4 + length);
      _messages.add(SyncMessage.decode(payload));
      bytes = bytes.sublist(4 + length);
    }
    if (bytes.isNotEmpty) _buffer.add(bytes);
  }
}
