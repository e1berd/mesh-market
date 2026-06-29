import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/pairing.dart';
import '../platform/sync_controller.dart';
import '../transport/lan_beacon.dart';
import 'nearby_devices_provider.dart';
import 'peers_provider.dart';
import 'sync_provider.dart';

enum PairOutcome { paired, storedLocally, failed }

final pairingControllerProvider = Provider<PairingController>(
  PairingController.new,
);

class PairingController {
  PairingController(this.ref);

  final Ref ref;

  Future<PairOutcome> pairByPayload(
    PairingPayload peer, {
    bool storeIfUnreachable = false,
  }) async {
    final service = await ref.read(syncControllerProvider.future);
    final match = _find(peer.deviceId) ?? await _await(service, peer.deviceId);
    if (match != null && await service.pairAt(match.address, match.port)) {
      return PairOutcome.paired;
    }

    if (await service.pairViaCode(peer.deviceId)) {
      return PairOutcome.paired;
    }

    if (storeIfUnreachable) {
      await ref.read(pairedPeersProvider.notifier).add(peer);
      return PairOutcome.storedLocally;
    }
    return PairOutcome.failed;
  }

  Future<PairOutcome> pairByCode(String code) async {
    final service = await ref.read(syncControllerProvider.future);
    final paired = await service.pairViaCode(code);
    return paired ? PairOutcome.paired : PairOutcome.failed;
  }

  LanPeer? _find(String deviceId) {
    for (final peer
        in ref.read(nearbyDevicesProvider).value ?? const <LanPeer>[]) {
      if (peer.deviceId == deviceId) return peer;
    }
    return null;
  }

  Future<LanPeer?> _await(SyncController service, String deviceId) async {
    try {
      return await service.nearby
          .firstWhere((peer) => peer.deviceId == deviceId)
          .timeout(const Duration(seconds: 5));
    } on Object {
      return null;
    }
  }
}
