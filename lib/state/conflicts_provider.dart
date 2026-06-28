import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/conflict.dart';
import '../core/models.dart';
import 'folders_provider.dart';

final folderConflictsProvider =
    FutureProvider.family<List<FolderConflict>, String>((ref, folderId) async {
      final folders = await ref.watch(foldersProvider.future);
      FolderConfig? folder;
      for (final candidate in folders) {
        if (candidate.id == folderId) {
          folder = candidate;
          break;
        }
      }
      if (folder == null || folder.localPath.isEmpty) return const [];

      final dir = Directory(folder.localPath);
      if (!await dir.exists()) return const [];

      final conflicts = <FolderConflict>[];
      await for (final entry in dir.list(recursive: true, followLinks: false)) {
        if (entry is File && isConflictPath(entry.path)) {
          conflicts.add(
            FolderConflict(
              folderId: folderId,
              originalPath: originalOf(entry.path),
              conflictPath: entry.path,
            ),
          );
        }
      }
      conflicts.sort((a, b) => a.conflictName.compareTo(b.conflictName));
      return conflicts;
    });
