import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../core/folder_share.dart';
import '../core/models.dart';
import '../core/paths.dart';
import '../storage/file_store.dart';
import '../sync/index.dart';
import '../sync/scanner.dart';
import '../transport/swarm.dart';
import 'identity_provider.dart';

final foldersProvider =
    AsyncNotifierProvider<FoldersNotifier, List<FolderConfig>>(
        FoldersNotifier.new);

final folderFileCountProvider =
    FutureProvider.family<int, String>((ref, folderId) async {
  final database = await ref.read(databaseProvider.future);
  final entries = await FolderIndex(database, folderId).all();
  return entries.where((entry) => !entry.meta.deleted).length;
});

class FoldersNotifier extends AsyncNotifier<List<FolderConfig>> {
  late File _file;

  @override
  Future<List<FolderConfig>> build() async {
    _file = File(p.join((await appDataDir()).path, 'folders.json'));
    if (!await _file.exists()) return const [];
    final list = jsonDecode(await _file.readAsString()) as List;
    return [
      for (final item in list) _fromMap((item as Map).cast<String, Object?>()),
    ];
  }

  Future<void> add(String path) async {
    final folder = FolderConfig(
      id: DateTime.now().microsecondsSinceEpoch.toRadixString(36),
      label: p.basename(path),
      localPath: path,
      swarmSecret: newSwarmSecret(),
    );
    await _persist([...?state.value, folder]);
    await scan(folder);
  }

  Future<void> remove(String id) async =>
      _persist([...?state.value]..removeWhere((folder) => folder.id == id));

  FolderShare shareOf(FolderConfig folder) => FolderShare(
        folderId: folder.id,
        label: folder.label,
        swarmSecret: folder.swarmSecret,
      );

  Future<void> addPeer(String folderId, String peerId) async => _persist([
        for (final folder in [...?state.value])
          folder.id == folderId && !folder.peerIds.contains(peerId)
              ? FolderConfig(
                  id: folder.id,
                  label: folder.label,
                  localPath: folder.localPath,
                  swarmSecret: folder.swarmSecret,
                  peerIds: [...folder.peerIds, peerId],
                )
              : folder,
      ]);

  Future<void> acceptShare(
      FolderShare share, String localPath, String peerId) async {
    final existing = [...?state.value];
    if (existing.any((folder) => folder.id == share.folderId)) {
      await addPeer(share.folderId, peerId);
      return;
    }
    final folder = FolderConfig(
      id: share.folderId,
      label: share.label,
      localPath: localPath,
      swarmSecret: share.swarmSecret,
      peerIds: [peerId],
    );
    await _persist([...existing, folder]);
    await scan(folder);
  }

  Future<int> scan(FolderConfig folder) async {
    final identity = await ref.read(identityProvider.future);
    final database = await ref.read(databaseProvider.future);
    final index = FolderIndex(database, folder.id);
    await FolderScanner(
      deviceId: identity.id,
      index: index,
      store: IoFileStore(Directory(folder.localPath)),
    ).scan();
    ref.invalidate(folderFileCountProvider(folder.id));
    return (await index.all()).where((entry) => !entry.meta.deleted).length;
  }

  Future<void> _persist(List<FolderConfig> folders) async {
    await _file.writeAsString(jsonEncode([for (final f in folders) _toMap(f)]));
    state = AsyncData(folders);
  }

  Map<String, Object?> _toMap(FolderConfig folder) => {
        'id': folder.id,
        'label': folder.label,
        'path': folder.localPath,
        'swarm': base64Encode(folder.swarmSecret),
        'peers': folder.peerIds,
      };

  FolderConfig _fromMap(Map<String, Object?> map) => FolderConfig(
        id: map['id'] as String,
        label: map['label'] as String,
        localPath: map['path'] as String,
        swarmSecret: base64Decode(map['swarm'] as String),
        peerIds: (map['peers'] as List?)?.cast<String>() ?? const [],
      );
}
