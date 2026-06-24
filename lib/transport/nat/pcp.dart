import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'gateway.dart';
import 'port_mapping.dart';

const _pcpPort = 5351;
const _pcpVersion = 2;
const _opMap = 1;
const _resultSuccess = 0;

final _random = Random.secure();

class PcpClient implements PortMapBackend {
  PcpClient(this.route);

  final GatewayRoute route;

  @override
  String get name => 'PCP';

  @override
  Future<PortMapping?> request({
    required int internalPort,
    required MapProtocol protocol,
    required Duration lifetime,
  }) async {
    final nonce = _nonce();
    final reply = await _map(
      nonce: nonce,
      internalPort: internalPort,
      protocol: protocol,
      lifetimeSeconds: lifetime.inSeconds,
    );
    if (reply == null) return null;
    final view = ByteData.sublistView(reply);
    if (view.getUint8(3) != _resultSuccess) return null;
    if (!_sameNonce(reply, nonce)) return null;
    if (view.getUint16(40) != internalPort) return null;
    return PortMapping(
      protocol: protocol,
      internalPort: internalPort,
      externalPort: view.getUint16(42),
      externalAddress: _readAddress(reply, 44),
      lifetime: Duration(seconds: view.getUint32(4)),
      via: name,
    );
  }

  @override
  Future<void> release(PortMapping mapping) => _map(
    nonce: _nonce(),
    internalPort: mapping.internalPort,
    protocol: mapping.protocol,
    lifetimeSeconds: 0,
  );

  Future<Uint8List?> _map({
    required Uint8List nonce,
    required int internalPort,
    required MapProtocol protocol,
    required int lifetimeSeconds,
  }) async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    try {
      final request = _buildRequest(
        nonce: nonce,
        internalPort: internalPort,
        protocol: protocol,
        lifetimeSeconds: lifetimeSeconds,
      );
      return _exchange(socket, request);
    } finally {
      socket.close();
    }
  }

  Uint8List _buildRequest({
    required Uint8List nonce,
    required int internalPort,
    required MapProtocol protocol,
    required int lifetimeSeconds,
  }) {
    final packet = Uint8List(60);
    final view = ByteData.sublistView(packet);
    view.setUint8(0, _pcpVersion);
    view.setUint8(1, _opMap);
    view.setUint32(4, lifetimeSeconds);
    _writeAddress(packet, 8, route.local);
    packet.setRange(24, 36, nonce);
    view.setUint8(36, protocol == MapProtocol.tcp ? 6 : 17);
    view.setUint16(40, internalPort);
    view.setUint16(42, internalPort);
    _writeAddress(packet, 44, InternetAddress.anyIPv4);
    return packet;
  }

  Future<Uint8List?> _exchange(
    RawDatagramSocket socket,
    Uint8List payload,
  ) async {
    final completer = Completer<Uint8List?>();
    late StreamSubscription<RawSocketEvent> sub;
    sub = socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      final datagram = socket.receive();
      if (datagram == null) return;
      if (datagram.address.address != route.gateway.address) return;
      final data = datagram.data;
      if (data.length < 60) return;
      if (data[0] != _pcpVersion) return;
      if (data[1] != (_opMap | 0x80)) return;
      if (!completer.isCompleted) completer.complete(data);
    });

    Timer? retry;
    var attempt = 0;
    void send() {
      if (attempt++ >= 3) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }
      socket.send(payload, route.gateway, _pcpPort);
      retry = Timer(Duration(milliseconds: 300 * attempt), send);
    }

    send();
    try {
      return await completer.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );
    } finally {
      retry?.cancel();
      await sub.cancel();
    }
  }

  Uint8List _nonce() =>
      Uint8List.fromList(List.generate(12, (_) => _random.nextInt(256)));

  bool _sameNonce(Uint8List reply, Uint8List nonce) {
    for (var i = 0; i < 12; i++) {
      if (reply[24 + i] != nonce[i]) return false;
    }
    return true;
  }

  void _writeAddress(Uint8List packet, int offset, InternetAddress address) {
    if (address.type == InternetAddressType.IPv6) {
      packet.setRange(offset, offset + 16, address.rawAddress);
      return;
    }
    packet[offset + 10] = 0xff;
    packet[offset + 11] = 0xff;
    packet.setRange(offset + 12, offset + 16, address.rawAddress);
  }

  InternetAddress? _readAddress(Uint8List packet, int offset) {
    final raw = packet.sublist(offset, offset + 16);
    final mapped = raw.sublist(0, 12);
    final isV4Mapped =
        mapped[10] == 0xff &&
        mapped[11] == 0xff &&
        mapped.take(10).every((byte) => byte == 0);
    if (isV4Mapped) {
      return InternetAddress.fromRawAddress(raw.sublist(12, 16));
    }
    return InternetAddress.fromRawAddress(raw);
  }
}
