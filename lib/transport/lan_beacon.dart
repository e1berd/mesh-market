import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/pairing.dart';

class LanPeer {
  const LanPeer(this.payload, this.address, this.port, {this.syncPort});

  final PairingPayload payload;
  final InternetAddress address;
  final int port;
  final int? syncPort;

  String get deviceId => payload.deviceId;
}

class LanBeacon {
  LanBeacon({
    required this.payload,
    required this.servicePort,
    this.syncPort,
    this.beaconPort = 49321,
  });

  final PairingPayload payload;
  final int servicePort;
  final int? syncPort;
  final int beaconPort;

  final _group = InternetAddress('239.255.42.99');
  final _broadcast = InternetAddress('255.255.255.255');
  final _peers = StreamController<LanPeer>.broadcast();

  RawDatagramSocket? _socket;
  Timer? _timer;

  Stream<LanPeer> get peers => _peers.stream;

  Future<void> start() async {
    final socket = await _bind();
    socket.broadcastEnabled = true;
    await _joinMulticast(socket);
    socket.listen(_onEvent);
    _socket = socket;
    _announce();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _announce());
  }

  Future<RawDatagramSocket> _bind() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        beaconPort,
        reuseAddress: true,
      );
    }
    try {
      return await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        beaconPort,
        reuseAddress: true,
        reusePort: true,
      );
    } on Object {
      return RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        beaconPort,
        reuseAddress: true,
      );
    }
  }

  Future<void> _joinMulticast(RawDatagramSocket socket) async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      if (interfaces.isEmpty) {
        socket.joinMulticast(_group);
        return;
      }
      for (final interface in interfaces) {
        try {
          socket.joinMulticast(_group, interface);
        } on Object {
          continue;
        }
      }
    } on Object {
      return;
    }
  }

  void _announce() {
    final data = utf8.encode(
      jsonEncode({
        ...payload.toJson(),
        'port': servicePort,
        if (syncPort != null) 'syncPort': syncPort,
      }),
    );
    try {
      final multicast = _socket?.send(data, _group, beaconPort) ?? -1;
      final broadcast = _socket?.send(data, _broadcast, beaconPort) ?? -1;
      debugPrint(
        '[pm.beacon] announce mcast=$multicast bcast=$broadcast '
        'port=$servicePort',
      );
    } on Object catch (error) {
      debugPrint('[pm.beacon] announce failed: $error');
    }
  }

  void _onEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final datagram = _socket?.receive();
    if (datagram == null) return;
    final peer = _parse(datagram.data, datagram.address);
    if (peer != null && peer.deviceId != payload.deviceId) {
      debugPrint(
        '[pm.beacon] rx ${peer.deviceId} @${datagram.address.address}',
      );
      _peers.add(peer);
    }
  }

  LanPeer? _parse(List<int> data, InternetAddress address) {
    try {
      final map = (jsonDecode(utf8.decode(data)) as Map)
          .cast<String, Object?>();
      return LanPeer(
        PairingPayload.fromJson(map),
        address,
        map['port']! as int,
        syncPort: map['syncPort'] as int?,
      );
    } on Object {
      return null;
    }
  }

  Future<void> stop() async {
    _timer?.cancel();
    _socket?.close();
    await _peers.close();
  }
}
