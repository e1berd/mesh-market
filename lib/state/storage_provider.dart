import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'folders_provider.dart';

final totalStorageProvider = FutureProvider<int>((ref) async {
  final folders = await ref.watch(foldersProvider.future);
  var total = 0;
  for (final folder in folders) {
    total += await ref.watch(folderSizeProvider(folder.id).future);
  }
  return total;
});

final deviceStorageProvider = FutureProvider.family<int, String>((
  ref,
  deviceId,
) async {
  final folders = await ref.watch(foldersProvider.future);
  var total = 0;
  for (final folder in folders) {
    if (folder.peerIds.contains(deviceId)) {
      total += await ref.watch(folderSizeProvider(folder.id).future);
    }
  }
  return total;
});
