import 'dart:io';
import 'dart:typed_data';

abstract interface class FileStore {
  Future<List<String>> paths();
  Future<int> length(String path);
  Future<DateTime> modified(String path);
  Future<Uint8List> readRange(String path, int offset, int length);
  Future<void> writeBytes(String path, Uint8List bytes);
  Future<void> delete(String path);
  Future<void> rename(String from, String to);
}

class IoFileStore implements FileStore {
  IoFileStore(this.root);

  final Directory root;

  File _file(String path) => File('${root.path}${Platform.pathSeparator}$path');

  @override
  Future<List<String>> paths() async {
    if (!await root.exists()) return const [];
    final prefix = root.path.length + 1;
    final result = <String>[];
    final entries = root.list(recursive: true, followLinks: false).handleError(
          (Object _) {},
        );
    await for (final entry in entries) {
      if (entry is File) result.add(entry.path.substring(prefix));
    }
    return result;
  }

  @override
  Future<int> length(String path) => _file(path).length();

  @override
  Future<DateTime> modified(String path) async =>
      (await _file(path).stat()).modified;

  @override
  Future<Uint8List> readRange(String path, int offset, int length) async {
    final handle = await _file(path).open();
    try {
      await handle.setPosition(offset);
      return await handle.read(length);
    } finally {
      await handle.close();
    }
  }

  @override
  Future<void> writeBytes(String path, Uint8List bytes) async {
    final target = _file(path);
    await target.parent.create(recursive: true);
    final staged = File('${target.path}.part');
    await staged.writeAsBytes(bytes, flush: true);
    await staged.rename(target.path);
  }

  @override
  Future<void> delete(String path) async {
    final target = _file(path);
    if (await target.exists()) await target.delete();
  }

  @override
  Future<void> rename(String from, String to) async {
    final destination = _file(to);
    await destination.parent.create(recursive: true);
    await _file(from).rename(destination.path);
  }
}
