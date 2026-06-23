import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../transport/hotspot.dart';
import '../transport/multipeer_transport.dart';
import '../transport/nfc_pairing.dart';
import '../transport/wifi_aware_transport.dart';
import '../transport/wifi_direct_transport.dart';

class TransportSupport {
  const TransportSupport({
    required this.wifiDirect,
    required this.multipeer,
    required this.wifiAware,
    required this.hotspot,
    required this.nfc,
  });

  final bool wifiDirect;
  final bool multipeer;
  final bool wifiAware;
  final bool hotspot;
  final bool nfc;

  bool get any => wifiDirect || multipeer || wifiAware || hotspot || nfc;

  static const none = TransportSupport(
    wifiDirect: false,
    multipeer: false,
    wifiAware: false,
    hotspot: false,
    nfc: false,
  );
}

final transportSupportProvider = FutureProvider<TransportSupport>((ref) async {
  final results = await Future.wait([
    WifiDirectTransport.isSupported(),
    MultipeerTransport.isSupported(),
    WifiAwareTransport.isSupported(),
    HotspotController.isSupported(),
    NfcPairing.isAvailable(),
  ]);
  return TransportSupport(
    wifiDirect: results[0],
    multipeer: results[1],
    wifiAware: results[2],
    hotspot: results[3],
    nfc: results[4],
  );
});
