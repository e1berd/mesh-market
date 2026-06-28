import 'dart:async';
import 'dart:io';

import 'package:sembast/sembast.dart';

import '../core/folder_share.dart';
import '../core/models.dart';
import '../core/pairing.dart';
import '../core/paths.dart';
import '../state/sync_schedule_provider.dart';
import '../storage/file_store.dart';
import '../transport/lan_beacon.dart';
import '../transport/swarm.dart';
import 'app_state_loader.dart';
import 'index.dart';
import 'sync_event.dart';
import 'sync_service.dart';

typedef IncomingPairHandler =
    Future<bool> Function(PairingPayload requester, String code);
typedef IncomingShareHandler =
    Future<bool> Function(FolderShare share, String fromDeviceId);

class SyncHost {
  SyncHost({
    this.onEvent,
    this.onFolderChanged,
    this.onNearby,
    this.onPaired,
    this.onProgress,
    IncomingPairHandler? onIncomingPair,
    IncomingShareHandler? onIncomingShare,
  }) : _onIncomingPair = onIncomingPair ?? ((_, _) async => false),
       _onIncomingShare = onIncomingShare ?? ((_, _) async => false);

  final void Function(SyncEvent event)? onEvent;
  final void Function(String folderId)? onFolderChanged;
  final void Function(SyncProgress progress)? onProgress;
  final void Function(LanPeer peer)? onNearby;
  final void Function(PairingPayload peer)? onPaired;
  final IncomingPairHandler _onIncomingPair;
  final IncomingShareHandler _onIncomingShare;

  late final Directory _dir;
  late final Database _database;
  SyncService? _service;
  StreamSubscription<LanPeer>? _nearbySub;
  var _peers = <PairingPayload>[];

  SyncService get service => _service!;

  Future<void> start() async {
    _dir = await appDataDir();
    _database = await loadDatabase(_dir);
    await _startService();
  }

  Future<void> restart() async {
    await _nearbySub?.cancel();
    final svc = _service;
    if (svc != null) await svc.stop();
    await _startService();
  }

  Future<void> _startService() async {
    final identity = await loadIdentity(_dir);
    final deviceName = await loadDeviceName(_dir);
    final config = await loadConfig();
    _peers = await loadPeers(_dir);
    final folders = await loadFolders(_dir);

    final svc = SyncService(
      identity: identity,
      deviceName: deviceName,
      config: config,
      peers: _peers,
      folders: await _runtimes(folders),
      onIncomingPair: _onIncomingPair,
      onPaired: _persistPaired,
      onIncomingShare: _onIncomingShare,
      onEvent: onEvent,
      onFolderChanged: onFolderChanged,
      onProgress: onProgress,
    );
    _service = svc;
    await svc.start();
    svc.setSyncActive(syncWindowActive(config, DateTime.now()));
    if (onNearby != null) _nearbySub = svc.nearby.listen(onNearby);
  }

  Future<List<FolderRuntime>> _runtimes(List<FolderConfig> list) async => [
    for (final folder in list)
      FolderRuntime(
        config: folder,
        index: FolderIndex(_database, folder.id),
        store: IoFileStore(Directory(folder.localPath)),
        infohash: await infohashFor(folder.swarmSecret),
      ),
  ];

  void _persistPaired(PairingPayload peer) {
    _peers = [
      ..._peers.where((existing) => existing.deviceId != peer.deviceId),
      peer,
    ];
    unawaited(savePeers(_dir, _peers));
    _service?.updatePeers(_peers);
    onPaired?.call(peer);
  }

  Future<void> reloadPeers() async {
    _peers = await loadPeers(_dir);
    _service?.updatePeers(_peers);
  }

  Future<void> reloadFolders() async {
    final svc = _service;
    if (svc == null) return;
    svc.updateFolders(await _runtimes(await loadFolders(_dir)));
  }

  Future<int> folderSize(String folderId) async {
    final entries = await FolderIndex(_database, folderId).all();
    return entries
        .where((entry) => !entry.meta.deleted)
        .fold<int>(0, (sum, entry) => sum + entry.meta.size);
  }

  Future<void> rescan(String folderId) async {
    await reloadFolders();
    _service?.rescanFolder(folderId);
  }

  void setSyncActive(bool active) => _service?.setSyncActive(active);

  Future<void> stop() async {
    await _nearbySub?.cancel();
    final svc = _service;
    if (svc != null) await svc.stop();
    await _database.close();
  }
}
