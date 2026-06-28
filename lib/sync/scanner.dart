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
    final meta = FileMeta(
      path: path,
      size: size,
      modified: modified,
      blockHashes: hashes,
    );

    if (existing != null &&
        !existing.meta.deleted &&
        _sameHashes(existing.meta.blockHashes, hashes)) {
      await index.put(IndexEntry(meta, existing.version));
      return;
    }

    final version = (existing?.version ?? VersionVector.empty).increment(
      deviceId,
    );
    await index.put(IndexEntry(meta, version));
  }

  bool _sameHashes(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<List<String>> _hashFile(String path, int size) async {
    const chunk = blockSize * 64;
    final hashes = <String>[];
    for (var offset = 0; offset < size; offset += chunk) {
      final length = offset + chunk < size ? chunk : size - offset;
      hashes.addAll(
        await hashBlocks(await store.readRange(path, offset, length)),
      );
    }
    return hashes;
  }

  Future<void> _markDeleted(IndexEntry entry) async {
    await index.put(
      IndexEntry(
        FileMeta(
          path: entry.meta.path,
          size: 0,
          modified: DateTime.now().toUtc(),
          blockHashes: const [],
          deleted: true,
        ),
        entry.version.increment(deviceId),
      ),
    );
  }
}
