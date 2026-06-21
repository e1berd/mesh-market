import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models.dart';
import '../storage/file_store.dart';
import '../sync/index.dart';
import '../sync/sync_service.dart';
import '../transport/swarm.dart';
import 'app_providers.dart';
import 'events_provider.dart';
import 'folders_provider.dart';
import 'identity_provider.dart';
import 'incoming_pair_provider.dart';
import 'incoming_share_provider.dart';
import 'peers_provider.dart';
import 'sync_schedule_provider.dart';

final syncServiceProvider = FutureProvider<SyncService>((ref) async {
  final identity = await ref.watch(identityProvider.future);
  final deviceName = await ref.watch(deviceNameProvider.future);
  final config = ref.watch(configProvider);
  final database = await ref.watch(databaseProvider.future);
  final peers = await ref.read(pairedPeersProvider.future);
  final folders = await ref.read(foldersProvider.future);

  Future<List<FolderRuntime>> runtimes(List<FolderConfig> list) async => [
    for (final folder in list)
      FolderRuntime(
        config: folder,
        index: FolderIndex(database, folder.id),
        store: IoFileStore(Directory(folder.localPath)),
        infohash: await infohashFor(folder.swarmSecret),
      ),
  ];

  final service = SyncService(
    identity: identity,
    deviceName: deviceName,
    config: config,
    peers: peers,
    folders: await runtimes(folders),
    onIncomingPair: (payload, code) async => ref.mounted &&
        await ref.read(incomingPairProvider.notifier).request(payload, code),
    onPaired: (peer) {
      if (ref.mounted) ref.read(pairedPeersProvider.notifier).add(peer);
    },
    onIncomingShare: (share, fromDeviceId) async => ref.mounted &&
        await ref
            .read(incomingShareProvider.notifier)
            .request(share, fromDeviceId),
    onEvent: (event) {
      if (ref.mounted) ref.read(syncEventsProvider.notifier).add(event);
    },
    onFolderChanged: (folderId) {
      if (ref.mounted) ref.invalidate(folderFileCountProvider(folderId));
    },
  );
  await service.start();
  service.setSyncActive(
    syncWindowActive(ref.read(configProvider), DateTime.now()),
  );

  ref.listen(syncActiveProvider, (_, next) {
    final active = next.value;
    if (active != null) service.setSyncActive(active);
  });
  ref.listen(foldersProvider, (_, next) async {
    final list = next.value;
    if (list != null) service.updateFolders(await runtimes(list));
  });
  ref.listen(pairedPeersProvider, (_, next) {
    final list = next.value;
    if (list != null) service.updatePeers(list);
  });

  ref.onDispose(service.stop);
  return service;
});
