import 'dart:io';
import 'dart:typed_data';

class GatewayRoute {
  const GatewayRoute({required this.local, required this.gateway});

  final InternetAddress local;
  final InternetAddress gateway;

  @override
  String toString() => '${local.address} via ${gateway.address}';
}

bool _isPrivateV4(InternetAddress address) {
  if (address.type != InternetAddressType.IPv4) return false;
  final octets = address.rawAddress;
  return switch (octets[0]) {
    10 => true,
    172 => octets[1] >= 16 && octets[1] <= 31,
    192 => octets[1] == 168,
    _ => false,
  };
}

InternetAddress _withLastOctet(InternetAddress base, int last) {
  final octets = Uint8List.fromList(base.rawAddress)..[3] = last;
  return InternetAddress.fromRawAddress(octets);
}

Future<List<GatewayRoute>> gatewayRoutes() async {
  final interfaces = await NetworkInterface.list(
    type: InternetAddressType.IPv4,
    includeLoopback: false,
  );
  final seen = <String>{};
  final routes = <GatewayRoute>[];
  for (final interface in interfaces) {
    for (final address in interface.addresses) {
      if (!_isPrivateV4(address)) continue;
      for (final last in const [1, 254]) {
        final gateway = _withLastOctet(address, last);
        if (gateway.address == address.address) continue;
        if (seen.add('${address.address}>${gateway.address}')) {
          routes.add(GatewayRoute(local: address, gateway: gateway));
        }
      }
    }
  }
  return routes;
}
