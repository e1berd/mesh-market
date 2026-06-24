import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'gateway.dart';
import 'port_mapping.dart';

const _pmpPort = 5351;
const _pmpVersion = 0;

class NatPmpClient implements PortMapBackend {
  NatPmpClient(this.route);

  final GatewayRoute route;

  @override
  String get name => 'NAT-PMP';

  @override
  Future<PortMapping?> request({
    required int internalPort,
    required MapProtocol protocol,
    required Duration lifetime,
  }) async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    try {
      final external = await _externalAddress(socket);
      if (external == null) return null;
      final opcode = protocol == MapProtocol.tcp ? 2 : 1;
      final body = ByteData(12)
        ..setUint8(0, _pmpVersion)
        ..setUint8(1, opcode)
        ..setUint16(4, internalPort)
        ..setUint16(6, internalPort)
        ..setUint32(8, lifetime.inSeconds);
      final reply = await _exchange(
        socket,
        body.buffer.asUint8List(),
        expectedOp: 128 + opcode,
        minLength: 16,
      );
      if (reply == null) return null;
      final view = ByteData.sublistView(reply);
      if (view.getUint16(2) != 0) return null;
      final mappedInternal = view.getUint16(8);
      if (mappedInternal != internalPort) return null;
      return PortMapping(
        protocol: protocol,
        internalPort: internalPort,
        externalPort: view.getUint16(10),
        externalAddress: external,
        lifetime: Duration(seconds: view.getUint32(12)),
        via: name,
      );
    } finally {
      socket.close();
    }
  }

  @override
  Future<void> release(PortMapping mapping) async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    try {
      final opcode = mapping.protocol == MapProtocol.tcp ? 2 : 1;
      final body = ByteData(12)
        ..setUint8(0, _pmpVersion)
        ..setUint8(1, opcode)
        ..setUint16(4, mapping.internalPort)
        ..setUint16(6, 0)
        ..setUint32(8, 0);
      await _exchange(
        socket,
        body.buffer.asUint8List(),
        expectedOp: 128 + opcode,
        minLength: 16,
      );
    } finally {
      socket.close();
    }
  }

  Future<InternetAddress?> _externalAddress(RawDatagramSocket socket) async {
    final reply = await _exchange(
      socket,
      Uint8List.fromList(const [_pmpVersion, 0]),
      expectedOp: 128,
      minLength: 12,
    );
    if (reply == null) return null;
    final view = ByteData.sublistView(reply);
    if (view.getUint16(2) != 0) return null;
    return InternetAddress.fromRawAddress(reply.sublist(8, 12));
  }

  Future<Uint8List?> _exchange(
    RawDatagramSocket socket,
    Uint8List payload, {
    required int expectedOp,
    required int minLength,
  }) async {
    final completer = Completer<Uint8List?>();
    late StreamSubscription<RawSocketEvent> sub;
    sub = socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      final datagram = socket.receive();
      if (datagram == null) return;
      if (datagram.address.address != route.gateway.address) return;
      final data = datagram.data;
      if (data.length < minLength) return;
      if (data[0] != _pmpVersion || data[1] != expectedOp) return;
      if (!completer.isCompleted) completer.complete(data);
    });

    Timer? retry;
    var attempt = 0;
    void send() {
      if (attempt++ >= 3) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }
      socket.send(payload, route.gateway, _pmpPort);
      retry = Timer(Duration(milliseconds: 250 * attempt), send);
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
}
