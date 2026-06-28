import 'dart:async';
import 'dart:io';

import 'package:flutter_background_service/flutter_background_service.dart';

import '../core/folder_share.dart';
import '../core/pairing.dart';
import '../sync/sync_event.dart';
import '../transport/lan_beacon.dart';
import 'sync_codec.dart';
import 'sync_controller.dart';
import 'sync_messages.dart';

class RemoteSyncController implements SyncController {
  RemoteSyncController() {
    _rpcSub = _service.on(msgRpcResult).listen(_onRpcResult);
  }

  final _service = FlutterBackgroundService();
  final _rpc = <String, Completer<Object?>>{};
  late final StreamSubscription<Map<String, dynamic>?> _rpcSub;
  var _nextRpcId = 0;

  Future<void> start() async {
    if (!await _service.isRunning()) await _service.startService();
  }

  Stream<T> _listen<T>(String channel, T Function(Map<String, Object?>) decode) =>
      _service
          .on(channel)
          .where((event) => event != null)
          .map((event) => decode(event!.cast<String, Object?>()));

  @override
  Stream<SyncEvent> get events => _listen(msgEvent, syncEventFromJson);
  @override
  Stream<SyncProgress> get progress => _listen(msgProgress, syncProgressFromJson);
  @override
  Stream<LanPeer> get nearby => _listen(msgNearby, lanPeerFromJson);
  @override
  Stream<String> get folderChanged =>
      _listen(msgFolderChanged, (d) => d['folderId'] as String);
  @override
  Stream<PairingPayload> get paired => _listen(msgPaired, PairingPayload.fromJson);
  @override
  Stream<PairPrompt> get incomingPairs => _listen(
    msgPairPrompt,
    (d) => PairPrompt(
      d['id'] as String,
      PairingPayload.fromJson((d['requester'] as Map).cast<String, Object?>()),
      d['code'] as String,
    ),
  );
  @override
  Stream<SharePrompt> get incomingShares => _listen(
    msgSharePrompt,
    (d) => SharePrompt(
      d['id'] as String,
      FolderShare.fromJson((d['share'] as Map).cast<String, Object?>()),
      d['fromDeviceId'] as String,
    ),
  );

  @override
  void resolvePair(String id, bool accepted) =>
      _service.invoke(msgResolve, {'id': id, 'accepted': accepted});
  @override
  void resolveShare(String id, bool accepted) =>
      _service.invoke(msgResolve, {'id': id, 'accepted': accepted});

  @override
  void setSyncActive(bool active) =>
      _service.invoke(msgSetActive, {'active': active});
  @override
  Future<void> reloadPeers() async => _service.invoke(msgReloadPeers);
  @override
  Future<void> reloadFolders() async => _service.invoke(msgReloadFolders);
  @override
  Future<void> reloadConfig() async => _service.invoke(msgReloadConfig);

  @override
  Future<int> folderSize(String folderId) async =>
      await _call(opFolderSize, {'folderId': folderId}) as int? ?? 0;
  @override
  Future<void> rescan(String folderId) async =>
      _service.invoke(msgRescan, {'folderId': folderId});

  @override
  Future<bool> pairAt(InternetAddress address, int port) async =>
      await _call(opPairAt, {'address': address.address, 'port': port})
          as bool? ??
      false;
  @override
  Future<bool> pairViaCode(String code) async =>
      await _call(opPairViaCode, {'code': code}) as bool? ?? false;
  @override
  Future<bool> shareFolderWith(FolderShare share, PairingPayload peer) async =>
      await _call(opShareFolder, {'share': share.toJson(), 'peer': peer.toJson()})
          as bool? ??
      false;

  Future<Object?> _call(String op, Map<String, dynamic> args) {
    final id = '${_nextRpcId++}';
    final completer = Completer<Object?>();
    _rpc[id] = completer;
    _service.invoke(msgRpc, {'id': id, 'op': op, 'args': args});
    return completer.future.timeout(
      const Duration(seconds: 90),
      onTimeout: () {
        _rpc.remove(id);
        return null;
      },
    );
  }

  void _onRpcResult(Map<String, dynamic>? data) {
    if (data == null) return;
    final completer = _rpc.remove(data['id'] as String?);
    if (completer != null && !completer.isCompleted) {
      completer.complete(data['result']);
    }
  }

  @override
  Future<void> dispose() async => _rpcSub.cancel();
}
