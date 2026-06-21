import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models.dart';
import '../core/pairing.dart';
import '../transport/lan_beacon.dart';
import 'folders_provider.dart';
import 'nearby_devices_provider.dart';
import 'sync_provider.dart';

final shareControllerProvider = Provider<ShareController>(ShareController.new);

class ShareController {
  ShareController(this.ref);

  final Ref ref;

  Future<bool> shareWith(FolderConfig folder, PairingPayload peer) async {
    final match = _find(peer.deviceId);
    if (match == null) return false;
    final service = await ref.read(syncServiceProvider.future);
    final share = ref.read(foldersProvider.notifier).shareOf(folder);
    final accepted =
        await service.shareFolder(share, peer, match.address, match.port);
    if (accepted) {
      await ref.read(foldersProvider.notifier).addPeer(folder.id, peer.deviceId);
    }
    return accepted;
  }

  LanPeer? _find(String deviceId) {
    for (final peer in ref.read(nearbyDevicesProvider).value ?? const <LanPeer>[]) {
      if (peer.deviceId == deviceId) return peer;
    }
    return null;
  }
}
