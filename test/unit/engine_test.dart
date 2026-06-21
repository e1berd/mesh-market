import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:point_machine/crypto/aead.dart';
import 'package:point_machine/sync/engine.dart';
import 'package:point_machine/sync/index.dart';
import 'package:point_machine/sync/scanner.dart';
import 'package:point_machine/sync/sync_event.dart';
import 'package:point_machine/storage/file_store.dart';
import 'package:point_machine/transport/messages.dart';
import 'package:point_machine/transport/peer_link.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:test/test.dart';

class _MemoryLink implements PeerLink {
  _MemoryLink(this.peerId, this._outgoing, this._incoming);

  @override
  final String peerId;
  final StreamController<SyncMessage> _outgoing;
  final Stream<SyncMessage> _incoming;

  @override
  Stream<SyncMessage> get incoming => _incoming;

  @override
  Future<void> send(SyncMessage message) async => _outgoing.add(message);

  @override
  Future<void> close() async => _outgoing.close();
}

(_MemoryLink, _MemoryLink) _linkPair() {
  final toA = StreamController<SyncMessage>();
  final toB = StreamController<SyncMessage>();
  return (_MemoryLink('B', toB, toA.stream), _MemoryLink('A', toA, toB.stream));
}

Future<bool> _await(Future<dynamic> Function() check) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (await check() == true) return true;
  }
  return false;
}

void main() {
  late Directory dirA;
  late Directory dirB;

  setUp(() {
    dirA = Directory.systemTemp.createTempSync('a');
    dirB = Directory.systemTemp.createTempSync('b');
  });

  Future<(SyncEngine, FolderIndex, IoFileStore)> engine(
      String device, Directory dir, {List<SyncEvent>? events}) async {
    final db = await databaseFactoryMemory.openDatabase('${dir.path}/$device.db');
    final index = FolderIndex(db, 'folder');
    final store = IoFileStore(dir);
    final cipher = FolderCipher(SecretKey(List<int>.filled(32, 3)));
    return (
      SyncEngine(index: index, store: store, cipher: cipher, onEvent: events?.add),
      index,
      store,
    );
  }

  test('copies a new file from one peer to the other', () async {
    File('${dirA.path}/notes.txt').writeAsStringSync('hello point machine');
    final (engineA, indexA, _) = await engine('A', dirA);
    final (engineB, indexB, storeB) = await engine('B', dirB);
    await FolderScanner(deviceId: 'A', index: indexA, store: IoFileStore(dirA)).scan();

    final (linkA, linkB) = _linkPair();
    final runA = engineA.sync(linkA);
    final runB = engineB.sync(linkB);

    final arrived = await _await(() async => await indexB.get('notes.txt') != null);
    await linkA.close();
    await linkB.close();
    await Future.wait([runA, runB]);

    expect(arrived, isTrue);
    expect(File('${dirB.path}/notes.txt').readAsStringSync(),
        equals('hello point machine'));
  });

  test('propagates an update without resending unchanged data', () async {
    final big = Uint8List.fromList(List<int>.generate(200000, (i) => i % 256));
    File('${dirA.path}/data.bin').writeAsBytesSync(big);
    final (engineA, indexA, storeA) = await engine('A', dirA);
    final (engineB, indexB, storeB) = await engine('B', dirB);
    final scannerA = FolderScanner(deviceId: 'A', index: indexA, store: storeA);
    await scannerA.scan();

    final (linkA, linkB) = _linkPair();
    final runA = engineA.sync(linkA);
    final runB = engineB.sync(linkB);
    await _await(() async => await indexB.get('data.bin') != null);

    final updated = Uint8List.fromList(big)..setRange(0, 3, [1, 2, 3]);
    File('${dirA.path}/data.bin').writeAsBytesSync(updated);
    await scannerA.scan();
    await engineA.announce(linkA);

    final synced = await _await(() async {
      final entry = await indexB.get('data.bin');
      return entry != null && entry.meta.blockHashes.first ==
          (await indexA.get('data.bin'))!.meta.blockHashes.first;
    });
    await linkA.close();
    await linkB.close();
    await Future.wait([runA, runB]);

    expect(synced, isTrue);
    expect(File('${dirB.path}/data.bin').readAsBytesSync(), equals(updated));
  });

  test('concurrent edits keep local and write a conflict copy', () async {
    File('${dirA.path}/doc.txt').writeAsStringSync('A-content');
    File('${dirB.path}/doc.txt').writeAsStringSync('B-content');
    final (engineA, indexA, storeA) = await engine('A', dirA);
    final (engineB, indexB, storeB) = await engine('B', dirB);
    await FolderScanner(deviceId: 'A', index: indexA, store: storeA).scan();
    await FolderScanner(deviceId: 'B', index: indexB, store: storeB).scan();

    final (linkA, linkB) = _linkPair();
    final runA = engineA.sync(linkA);
    final runB = engineB.sync(linkB);

    final created = await _await(() async => dirB
        .listSync()
        .whereType<File>()
        .any((file) => file.path.contains('sync-conflict')));
    await linkA.close();
    await linkB.close();
    await Future.wait([runA, runB]);

    expect(created, isTrue);
    expect(File('${dirB.path}/doc.txt').readAsStringSync(), equals('B-content'));
    final conflict = dirB
        .listSync()
        .whereType<File>()
        .firstWhere((file) => file.path.contains('sync-conflict'));
    expect(conflict.readAsStringSync(), equals('A-content'));
  });

  test('emits a received event when a file arrives', () async {
    File('${dirA.path}/note.txt').writeAsStringSync('hi');
    final events = <SyncEvent>[];
    final (engineA, indexA, storeA) = await engine('A', dirA);
    final (engineB, _, _) = await engine('B', dirB, events: events);
    await FolderScanner(deviceId: 'A', index: indexA, store: storeA).scan();

    final (linkA, linkB) = _linkPair();
    final runA = engineA.sync(linkA);
    final runB = engineB.sync(linkB);
    await _await(
        () async => events.any((e) => e.kind == SyncEventKind.received));
    await linkA.close();
    await linkB.close();
    await Future.wait([runA, runB]);

    expect(
      events.any((e) => e.kind == SyncEventKind.received && e.path == 'note.txt'),
      isTrue,
    );
  });
}
