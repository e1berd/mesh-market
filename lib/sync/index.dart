import 'package:sembast/sembast.dart';

import '../core/models.dart';
import 'version_vector.dart';

class IndexEntry {
  const IndexEntry(this.meta, this.version);

  factory IndexEntry.fromMap(Map<String, Object?> map) => IndexEntry(
        FileMeta(
          path: map['path'] as String,
          size: map['size'] as int,
          modified: DateTime.fromMillisecondsSinceEpoch(
            map['modified'] as int,
            isUtc: true,
          ),
          blockHashes: (map['blocks'] as List).cast<String>(),
          deleted: map['deleted'] as bool? ?? false,
        ),
        VersionVector.fromMap((map['version'] as Map).cast<String, dynamic>()),
      );

  final FileMeta meta;
  final VersionVector version;

  Map<String, Object?> toMap() => {
        'path': meta.path,
        'size': meta.size,
        'modified': meta.modified.toUtc().millisecondsSinceEpoch,
        'blocks': meta.blockHashes,
        'deleted': meta.deleted,
        'version': version.toMap(),
      };
}

class FolderIndex {
  FolderIndex(this._db, String folderId)
      : _store = stringMapStoreFactory.store('index/$folderId');

  final Database _db;
  final StoreRef<String, Map<String, Object?>> _store;

  Future<void> put(IndexEntry entry) =>
      _store.record(entry.meta.path).put(_db, entry.toMap());

  Future<IndexEntry?> get(String path) async {
    final value = await _store.record(path).get(_db);
    return value == null ? null : IndexEntry.fromMap(value);
  }

  Future<List<IndexEntry>> all() async {
    final records = await _store.find(_db);
    return [for (final record in records) IndexEntry.fromMap(record.value)];
  }

  Future<void> delete(String path) => _store.record(path).delete(_db);
}
