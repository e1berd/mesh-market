import 'dart:io';

enum MapProtocol { tcp, udp }

class PortMapping {
  const PortMapping({
    required this.protocol,
    required this.internalPort,
    required this.externalPort,
    required this.externalAddress,
    required this.lifetime,
    required this.via,
  });

  final MapProtocol protocol;
  final int internalPort;
  final int externalPort;
  final InternetAddress? externalAddress;
  final Duration lifetime;
  final String via;

  @override
  String toString() =>
      '$via ${externalAddress?.address ?? '?'}:$externalPort'
      '->$internalPort (${lifetime.inSeconds}s)';
}

abstract interface class PortMapBackend {
  String get name;

  Future<PortMapping?> request({
    required int internalPort,
    required MapProtocol protocol,
    required Duration lifetime,
  });

  Future<void> release(PortMapping mapping);
}
