import 'dart:async';
import 'dart:convert';
import 'dart:io';

class LanPeer {
  const LanPeer(this.deviceId, this.address, this.port);

  final String deviceId;
  final InternetAddress address;
  final int port;
}

class LanBeacon {
  LanBeacon({
    required this.deviceId,
    required this.servicePort,
    this.beaconPort = 21027,
  });

  final String deviceId;
  final int servicePort;
  final int beaconPort;

  final _group = InternetAddress('239.255.42.99');
  final _peers = StreamController<LanPeer>.broadcast();

  RawDatagramSocket? _socket;
  Timer? _timer;

  Stream<LanPeer> get peers => _peers.stream;

  Future<void> start() async {
    final socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      beaconPort,
      reuseAddress: true,
      reusePort: true,
    );
    socket
      ..multicastLoopback = false
      ..joinMulticast(_group)
      ..listen(_onEvent);
    _socket = socket;
    _announce();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _announce());
  }

  void _announce() => _socket?.send(
        utf8.encode(jsonEncode({'id': deviceId, 'port': servicePort})),
        _group,
        beaconPort,
      );

  void _onEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final datagram = _socket?.receive();
    if (datagram == null) return;
    final peer = _parse(datagram.data, datagram.address);
    if (peer != null && peer.deviceId != deviceId) _peers.add(peer);
  }

  LanPeer? _parse(List<int> data, InternetAddress address) {
    try {
      final map = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
      return LanPeer(map['id'] as String, address, map['port'] as int);
    } on FormatException {
      return null;
    }
  }

  Future<void> stop() async {
    _timer?.cancel();
    _socket?.close();
    await _peers.close();
  }
}
