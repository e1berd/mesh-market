import 'dart:async';
import 'dart:io';

import '../messages.dart';
import '../nat/port_mapper.dart';
import '../peer_link.dart';
import 'candidates.dart';
import 'reliable.dart';
import 'udp_punch.dart';

class KcpLink implements PeerLink {
  KcpLink({required this.peerId, required PunchResult punch})
    : _socket = punch.socket,
      _remote = punch.remote,
      _mapper = punch.mapper {
    _transport = ReliableTransport(
      send: (datagram) => _socket.send(datagram, _remote.address, _remote.port),
    );
    _socketSub = _socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      final datagram = _socket.receive();
      if (datagram == null) return;
      if (datagram.address.address != _remote.address.address ||
          datagram.port != _remote.port) {
        return;
      }
      _transport.onDatagram(datagram.data);
    });
    _messageSub = _transport.messages.listen(
      (bytes) {
        try {
          _incoming.add(SyncMessage.decode(bytes));
        } on Object {
          return;
        }
      },
      onError: (_) => _closeIncoming(),
      onDone: _closeIncoming,
    );
    _ticker = Timer.periodic(
      const Duration(milliseconds: 50),
      (_) => _transport.tick(),
    );
  }

  @override
  final String peerId;

  final RawDatagramSocket _socket;
  final PunchCandidate _remote;
  final PortMapper? _mapper;
  late final ReliableTransport _transport;
  late final StreamSubscription<RawSocketEvent> _socketSub;
  late final StreamSubscription<Object?> _messageSub;
  late final Timer _ticker;
  final _incoming = StreamController<SyncMessage>();

  @override
  Stream<SyncMessage> get incoming => _incoming.stream;

  @override
  Future<void> send(SyncMessage message) async =>
      _transport.sendMessage(message.encode());

  @override
  Future<void> close() async {
    _ticker.cancel();
    await _transport.close();
    await _socketSub.cancel();
    await _messageSub.cancel();
    _socket.close();
    await _mapper?.dispose();
    await _closeIncoming();
  }

  Future<void> _closeIncoming() async {
    if (!_incoming.isClosed) await _incoming.close();
  }
}
