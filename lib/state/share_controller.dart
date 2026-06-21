import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models.dart';
import '../core/pairing.dart';
import 'folders_provider.dart';
import 'sync_provider.dart';

final shareControllerProvider = Provider<ShareController>(ShareController.new);

class ShareController {
  ShareController(this.ref);

  final Ref ref;

  Future<bool> shareWith(FolderConfig folder, PairingPayload peer) async {
    final share = ref.read(foldersProvider.notifier).shareOf(folder);
    await ref.read(foldersProvider.notifier).addPeer(folder.id, peer.deviceId);
    final service = await ref.read(syncServiceProvider.future);
    return service.shareFolderWith(share, peer);
  }
}
