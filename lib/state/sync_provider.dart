import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final syncServiceProvider = FutureProvider<SyncService>((ref) async {
  final identity = await ref.watch(identityProvider.future);
  final deviceName = await ref.watch(deviceNameProvider.future);
  final config = ref.watch(configProvider);
  final peers = await ref.watch(pairedPeersProvider.future);
  final folders = await ref.watch(foldersProvider.future);
  final database = await ref.watch(databaseProvider.future);

  final runtimes = <FolderRuntime>[
    for (final folder in folders)
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
    folders: runtimes,
    onIncomingPair: (payload, code) =>
        ref.read(incomingPairProvider.notifier).request(payload, code),
    onPaired: (peer) => ref.read(pairedPeersProvider.notifier).add(peer),
    onIncomingShare: (share, fromDeviceId) =>
        ref.read(incomingShareProvider.notifier).request(share, fromDeviceId),
    onEvent: (event) => ref.read(syncEventsProvider.notifier).add(event),
    onFolderChanged: (folderId) =>
        ref.invalidate(folderFileCountProvider(folderId)),
  );
  await service.start();
  ref.onDispose(service.stop);
  return service;
});
