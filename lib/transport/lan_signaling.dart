import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'signaling.dart';

class SocketSignalChannel implements SignalChannel {
  SocketSignalChannel(this._socket) {
    _subscription = _socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_onLine, onError: (_) {}, onDone: _closeIncoming);
  }

  final Socket _socket;
  final _incoming = StreamController<SignalMessage>.broadcast();
  late final StreamSubscription<String> _subscription;

  @override
  Stream<SignalMessage> get incoming => _incoming.stream;

  @override
  Future<void> send(SignalMessage message) async {
    _socket.write('${message.encode()}\n');
    await _socket.flush();
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await _socket.close();
    _closeIncoming();
  }

  void _onLine(String line) {
    if (line.isEmpty) return;
    try {
      _incoming.add(SignalMessage.decode(line));
    } on FormatException {
      return;
    }
  }

  void _closeIncoming() {
    if (!_incoming.isClosed) _incoming.close();
  }
}

class LanSignalingServer {
  LanSignalingServer(this.port);

  final int port;
  final _connections = StreamController<SignalChannel>.broadcast();

  ServerSocket? _server;

  int get boundPort => _server?.port ?? port;

  Stream<SignalChannel> get connections => _connections.stream;

  Future<void> start() async {
    final server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    server.listen((socket) => _connections.add(SocketSignalChannel(socket)));
    _server = server;
  }

  Future<void> stop() async {
    await _server?.close();
    await _connections.close();
  }
}

Future<SignalChannel> connectLanSignaling(
        InternetAddress address, int port) async =>
    SocketSignalChannel(await Socket.connect(address, port));
