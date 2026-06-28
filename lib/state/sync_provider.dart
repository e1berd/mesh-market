import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../platform/local_sync_controller.dart';
import '../platform/remote_sync_controller.dart';
import '../platform/sync_controller.dart';
import 'app_providers.dart';
import 'conflicts_provider.dart';
import 'events_provider.dart';
import 'folders_provider.dart';
import 'sync_progress_provider.dart';
import 'identity_provider.dart';
import 'incoming_pair_provider.dart';
import 'incoming_share_provider.dart';
import 'peers_provider.dart';
import 'sync_schedule_provider.dart';

bool get _useRemote => Platform.isAndroid || Platform.isIOS;

final FutureProvider<SyncController> syncControllerProvider =
    FutureProvider<SyncController>((ref) async {
  final SyncController controller;
  if (_useRemote) {
    final remote = RemoteSyncController();
    await remote.start();
    controller = remote;
  } else {
    final local = LocalSyncController();
    await local.start();
    controller = local;
  }

  final subscriptions = <StreamSubscription<dynamic>>[
    controller.events.listen((event) {
      if (ref.mounted) ref.read(syncEventsProvider.notifier).add(event);
    }),
    controller.progress.listen((progress) {
      if (ref.mounted) ref.read(syncProgressProvider.notifier).update(progress);
    }),
    controller.folderChanged.listen((folderId) {
      if (ref.mounted) {
        ref.invalidate(folderSizeProvider(folderId));
        ref.invalidate(folderConflictsProvider(folderId));
      }
    }),
    controller.paired.listen((peer) {
      if (ref.mounted) ref.read(pairedPeersProvider.notifier).add(peer);
    }),
    controller.incomingPairs.listen((prompt) async {
      final accepted = ref.mounted &&
          await ref
              .read(incomingPairProvider.notifier)
              .request(prompt.requester, prompt.code);
      controller.resolvePair(prompt.id, accepted);
    }),
    controller.incomingShares.listen((prompt) async {
      final accepted = ref.mounted &&
          await ref
              .read(incomingShareProvider.notifier)
              .request(prompt.share, prompt.fromDeviceId);
      controller.resolveShare(prompt.id, accepted);
    }),
  ];

  controller.setSyncActive(
    syncWindowActive(ref.read(configProvider), DateTime.now()),
  );

  ref.onDispose(() async {
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
    await controller.dispose();
  });
  return controller;
});

final syncBindingProvider = FutureProvider<void>((ref) async {
  final controller = await ref.watch(syncControllerProvider.future);

  ref.listen(syncActiveProvider, (_, next) {
    final active = next.value;
    if (active != null) controller.setSyncActive(active);
  });
  ref.listen(
    foldersProvider,
    (prev, next) {
      final folders = next.value;
      if (folders != null) {
        controller.reloadFolders();
        for (final folder in folders) {
          ref.invalidate(folderSizeProvider(folder.id));
        }
      }
    },
    fireImmediately: true,
  );
  ref.listen(pairedPeersProvider, (_, next) {
    if (next.value != null) controller.reloadPeers();
  });
  ref.listen(deviceNameProvider, (prev, next) {
    final before = prev?.value;
    final after = next.value;
    if (before != null && after != null && before != after) {
      controller.reloadConfig();
    }
  });
  ref.listen(
    configProvider.select(
      (c) => (c.lanDiscovery, c.dhtDiscovery, c.bluetoothDiscovery, c.iceServers),
    ),
    (_, _) => controller.reloadConfig(),
  );
});
