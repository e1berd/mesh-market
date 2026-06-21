import '../core/models.dart';
import '../storage/file_store.dart';
import 'blocks.dart';
import 'index.dart';
import 'version_vector.dart';

class FolderScanner {
  FolderScanner({
    required this.deviceId,
    required this.index,
    required this.store,
  });

  final String deviceId;
  final FolderIndex index;
  final FileStore store;

  Future<void> scan() async {
    final present = <String>{};
    for (final path in await store.paths()) {
      present.add(path);
      try {
        await _scanFile(path);
      } on Object {
        continue;
      }
    }
    for (final entry in await index.all()) {
      if (!entry.meta.deleted && !present.contains(entry.meta.path)) {
        await _markDeleted(entry);
      }
    }
  }

  Future<void> _scanFile(String path) async {
    final size = await store.length(path);
    final modified = (await store.modified(path)).toUtc();
    final existing = await index.get(path);
    if (existing != null &&
        !existing.meta.deleted &&
        existing.meta.size == size &&
        existing.meta.modified.isAtSameMomentAs(modified)) {
      return;
    }

    final hashes = await _hashFile(path, size);
    final version =
        (existing?.version ?? VersionVector.empty).increment(deviceId);
    await index.put(IndexEntry(
      FileMeta(
        path: path,
        size: size,
        modified: modified,
        blockHashes: hashes,
      ),
      version,
    ));
  }

  Future<List<String>> _hashFile(String path, int size) async {
    final hashes = <String>[];
    for (var offset = 0; offset < size; offset += blockSize) {
      hashes.add(await hashBytes(await store.readRange(path, offset, blockSize)));
    }
    return hashes;
  }

  Future<void> _markDeleted(IndexEntry entry) async {
    await index.put(IndexEntry(
      FileMeta(
        path: entry.meta.path,
        size: 0,
        modified: DateTime.now().toUtc(),
        blockHashes: const [],
        deleted: true,
      ),
      entry.version.increment(deviceId),
    ));
  }
}
