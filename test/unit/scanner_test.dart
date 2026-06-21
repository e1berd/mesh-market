import 'dart:io';

import 'package:point_machine/sync/index.dart';
import 'package:point_machine/sync/scanner.dart';
import 'package:point_machine/storage/file_store.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:test/test.dart';

void main() {
  test('scans files recursively, including nested directories', () async {
    final dir = Directory.systemTemp.createTempSync('scan');
    File('${dir.path}/a.txt').writeAsStringSync('alpha');
    Directory('${dir.path}/sub').createSync();
    File('${dir.path}/sub/b.txt').writeAsStringSync('beta');

    final db = await databaseFactoryMemory.openDatabase('${dir.path}/db');
    final index = FolderIndex(db, 'folder');
    await FolderScanner(deviceId: 'D', index: index, store: IoFileStore(dir)).scan();

    final live = (await index.all()).where((e) => !e.meta.deleted).toList();
    expect(live.length, equals(2));
    expect(live.map((e) => e.meta.path).toSet(), equals({'a.txt', 'sub/b.txt'}));
  });

  test('indexes files using the file-based database (app path)', () async {
    final dir = Directory.systemTemp.createTempSync('scanio');
    File('${dir.path}/a.txt').writeAsStringSync('x');
    Directory('${dir.path}/sub').createSync();
    File('${dir.path}/sub/b.txt').writeAsStringSync('y');

    final dbDir = Directory.systemTemp.createTempSync('scaniodb');
    final db = await databaseFactoryIo.openDatabase('${dbDir.path}/store.db');
    final index = FolderIndex(db, 'folder');
    await FolderScanner(deviceId: 'D', index: index, store: IoFileStore(dir)).scan();

    expect((await index.all()).where((e) => !e.meta.deleted).length, equals(2));
    await db.close();
  });
}
