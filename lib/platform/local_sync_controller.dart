import 'dart:async';
import 'dart:io';

import '../core/folder_share.dart';
import '../core/pairing.dart';
import '../sync/sync_event.dart';
import '../sync/sync_host.dart';
import '../transport/lan_beacon.dart';
import 'sync_controller.dart';

class LocalSyncController implements SyncController {
  final _events = StreamController<SyncEvent>.broadcast();
  final _progress = StreamController<SyncProgress>.broadcast();
  final _nearby = StreamController<LanPeer>.broadcast();
  final _folderChanged = StreamController<String>.broadcast();
  final _paired = StreamController<PairingPayload>.broadcast();
  final _pairs = StreamController<PairPrompt>.broadcast();
  final _shares = StreamController<SharePrompt>.broadcast();
  final _pending = <String, Completer<bool>>{};
  var _nextId = 0;

  late final SyncHost _host = SyncHost(
    onEvent: _events.add,
    onProgress: _progress.add,
    onFolderChanged: _folderChanged.add,
    onNearby: _nearby.add,
    onPaired: _paired.add,
    onIncomingPair: (requester, code) =>
        _prompt((id) => _pairs.add(PairPrompt(id, requester, code))),
    onIncomingShare: (share, fromDeviceId) =>
        _prompt((id) => _shares.add(SharePrompt(id, share, fromDeviceId))),
  );

  Future<void> start() => _host.start();

  Future<bool> _prompt(void Function(String id) emit) {
    final id = '${_nextId++}';
    final completer = Completer<bool>();
    _pending[id] = completer;
    emit(id);
    return completer.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        _pending.remove(id);
        return false;
      },
    );
  }

  void _resolve(String id, bool accepted) {
    final completer = _pending.remove(id);
    if (completer != null && !completer.isCompleted) completer.complete(accepted);
  }

  @override
  Stream<SyncEvent> get events => _events.stream;
  @override
  Stream<SyncProgress> get progress => _progress.stream;
  @override
  Stream<LanPeer> get nearby => _nearby.stream;
  @override
  Stream<String> get folderChanged => _folderChanged.stream;
  @override
  Stream<PairingPayload> get paired => _paired.stream;
  @override
  Stream<PairPrompt> get incomingPairs => _pairs.stream;
  @override
  Stream<SharePrompt> get incomingShares => _shares.stream;

  @override
  void resolvePair(String id, bool accepted) => _resolve(id, accepted);
  @override
  void resolveShare(String id, bool accepted) => _resolve(id, accepted);

  @override
  void setSyncActive(bool active) => _host.setSyncActive(active);
  @override
  Future<void> reloadPeers() => _host.reloadPeers();
  @override
  Future<void> reloadFolders() => _host.reloadFolders();
  @override
  Future<void> reloadConfig() => _host.restart();

  @override
  Future<int> folderSize(String folderId) => _host.folderSize(folderId);
  @override
  Future<void> rescan(String folderId) => _host.rescan(folderId);

  @override
  Future<bool> pairAt(InternetAddress address, int port) =>
      _host.service.pairAt(address, port);
  @override
  Future<bool> pairViaCode(String code) => _host.service.pairViaCode(code);
  @override
  Future<bool> shareFolderWith(FolderShare share, PairingPayload peer) =>
      _host.service.shareFolderWith(share, peer);

  @override
  Future<void> dispose() async {
    await _host.stop();
    await _events.close();
    await _progress.close();
    await _nearby.close();
    await _folderChanged.close();
    await _paired.close();
    await _pairs.close();
    await _shares.close();
  }
}
