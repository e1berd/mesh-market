import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/conflict.dart';
import '../core/models.dart';
import 'conflicts_provider.dart';
import 'folders_provider.dart';

final conflictControllerProvider = Provider<ConflictController>(
  ConflictController.new,
);

class ConflictController {
  ConflictController(this.ref);

  final Ref ref;

  Future<void> keepCurrent(FolderConflict conflict) async {
    await _deleteQuietly(conflict.conflictPath);
    await _refresh(conflict.folderId);
  }

  Future<void> useIncoming(FolderConflict conflict) async {
    final source = File(conflict.conflictPath);
    if (await source.exists()) {
      await File(conflict.originalPath).writeAsBytes(
        await source.readAsBytes(),
        flush: true,
      );
    }
    await _deleteQuietly(conflict.conflictPath);
    await _refresh(conflict.folderId);
  }

  Future<void> resolveAll(String folderId) async {
    final conflicts = await ref.read(folderConflictsProvider(folderId).future);
    for (final conflict in conflicts) {
      await _newestWins(conflict);
    }
    await _refresh(folderId);
  }

  Future<void> _newestWins(FolderConflict conflict) async {
    final incoming = File(conflict.conflictPath);
    if (!await incoming.exists()) return;
    final original = File(conflict.originalPath);
    final takeIncoming = !await original.exists() ||
        (await incoming.lastModified()).isAfter(await original.lastModified());
    if (takeIncoming) {
      await original.writeAsBytes(await incoming.readAsBytes(), flush: true);
    }
    await _deleteQuietly(conflict.conflictPath);
  }

  Future<void> _deleteQuietly(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  Future<void> _refresh(String folderId) async {
    final folders = ref.read(foldersProvider).value ?? const <FolderConfig>[];
    for (final folder in folders) {
      if (folder.id == folderId) {
        await ref.read(foldersProvider.notifier).scan(folder);
        break;
      }
    }
    ref.invalidate(folderConflictsProvider(folderId));
  }
}
