import 'dart:async';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';

import '../core/folder_share.dart';
import '../core/pairing.dart';
import '../sync/sync_host.dart';
import 'sync_codec.dart';
import 'sync_messages.dart';

@pragma('vm:entry-point')
Future<void> syncBackgroundEntry(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  await _BackgroundBridge(service).run();
}

class _BackgroundBridge {
  _BackgroundBridge(this.service);

  final ServiceInstance service;
  final _pending = <String, Completer<bool>>{};
  var _nextPromptId = 0;

  late final SyncHost _host = SyncHost(
    onEvent: (e) => service.invoke(msgEvent, syncEventToJson(e)),
    onProgress: (p) => service.invoke(msgProgress, syncProgressToJson(p)),
    onFolderChanged: (id) => service.invoke(msgFolderChanged, {'folderId': id}),
    onNearby: (p) => service.invoke(msgNearby, lanPeerToJson(p)),
    onPaired: (p) => service.invoke(msgPaired, p.toJson()),
    onIncomingPair: (requester, code) => _prompt(
      msgPairPrompt,
      {'requester': requester.toJson(), 'code': code},
    ),
    onIncomingShare: (share, fromDeviceId) => _prompt(
      msgSharePrompt,
      {'share': share.toJson(), 'fromDeviceId': fromDeviceId},
    ),
  );

  Future<void> run() async {
    _wireForeground();
    await _host.start();
    service.on(msgSetActive).listen(
      (d) => _host.setSyncActive(d?['active'] as bool? ?? false),
    );
    service.on(msgReloadPeers).listen((_) => _host.reloadPeers());
    service.on(msgReloadFolders).listen((_) => _host.reloadFolders());
    service.on(msgReloadConfig).listen((_) => _host.restart());
    service.on(msgRescan).listen((d) => _host.rescan(d?['folderId'] as String));
    service.on(msgResolve).listen(_onResolve);
    service.on(msgRpc).listen(_onRpc);
  }

  void _wireForeground() {
    if (service is AndroidServiceInstance) {
      final android = service as AndroidServiceInstance;
      android.setAsForegroundService();
      service.on('setAsForeground').listen((_) => android.setAsForegroundService());
      service.on('setAsBackground').listen((_) => android.setAsBackgroundService());
      service.on('updateNotification').listen((event) {
        android.setForegroundNotificationInfo(
          title: event?['title'] as String? ?? 'Mesh Market',
          content: event?['content'] as String? ?? 'Sync is active',
        );
      });
    }
    service.on('stopService').listen((_) async {
      await _host.stop();
      await service.stopSelf();
    });
  }

  Future<bool> _prompt(String channel, Map<String, dynamic> data) {
    final id = '${_nextPromptId++}';
    final completer = Completer<bool>();
    _pending[id] = completer;
    service.invoke(channel, {'id': id, ...data});
    return completer.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        _pending.remove(id);
        return false;
      },
    );
  }

  void _onResolve(Map<String, dynamic>? data) {
    if (data == null) return;
    final completer = _pending.remove(data['id'] as String?);
    if (completer != null && !completer.isCompleted) {
      completer.complete(data['accepted'] as bool? ?? false);
    }
  }

  Future<void> _onRpc(Map<String, dynamic>? data) async {
    if (data == null) return;
    final id = data['id'] as String;
    final args = (data['args'] as Map).cast<String, Object?>();
    Object? result;
    try {
      result = await _dispatch(data['op'] as String, args);
    } on Object {
      result = null;
    }
    service.invoke(msgRpcResult, {'id': id, 'result': result});
  }

  Future<Object?> _dispatch(String op, Map<String, Object?> args) async {
    switch (op) {
      case opPairAt:
        return _host.service.pairAt(
          parseAddress(args['address'] as String),
          args['port'] as int,
        );
      case opPairViaCode:
        return _host.service.pairViaCode(args['code'] as String);
      case opShareFolder:
        return _host.service.shareFolderWith(
          FolderShare.fromJson((args['share'] as Map).cast<String, Object?>()),
          PairingPayload.fromJson((args['peer'] as Map).cast<String, Object?>()),
        );
      case opFolderSize:
        return _host.folderSize(args['folderId'] as String);
      default:
        return false;
    }
  }
}
