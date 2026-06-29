import 'dart:typed_data';

import 'package:mesh_market/core/models.dart';
import 'package:mesh_market/core/pairing.dart';
import 'package:mesh_market/sync/index.dart';
import 'package:mesh_market/sync/version_vector.dart';
import 'package:mesh_market/transport/messages.dart';
import 'package:test/test.dart';

PairingPayload _payload(String id, String name) => PairingPayload(
  deviceId: id,
  name: name,
  signingKey: const [1, 2],
  agreementKey: const [3, 4],
);

void main() {
  test('open link round-trips device and folder id', () {
    final decoded =
        SyncMessage.decode(const OpenLink('DEVICE1', 'folder').encode())
            as OpenLink;
    expect(decoded.deviceId, equals('DEVICE1'));
    expect(decoded.folderId, equals('folder'));
  });

  test('hello round-trips device id and signature', () {
    final decoded =
        SyncMessage.decode(
              Hello(
                'DEVICE1',
                Uint8List.fromList([1, 2, 3]),
                payload: _payload('DEVICE1', 'Phone'),
              ).encode(),
            )
            as Hello;
    expect(decoded.deviceId, equals('DEVICE1'));
    expect(decoded.signature, equals([1, 2, 3]));
    expect(decoded.payload?.name, equals('Phone'));
  });

  test('index snapshot round-trips an entry', () {
    final entry = IndexEntry(
      FileMeta(
        path: 'a/b.bin',
        size: 5,
        modified: DateTime.utc(2026, 1, 2),
        blockHashes: const ['hash'],
      ),
      VersionVector.empty.increment('d1'),
    );
    final decoded =
        SyncMessage.decode(IndexSnapshot([entry]).encode()) as IndexSnapshot;
    expect(decoded.entries.single.meta.path, equals('a/b.bin'));
    expect(decoded.entries.single.meta.blockHashes, equals(['hash']));
    expect(decoded.entries.single.version.counters['d1'], equals(1));
  });

  test('want and block round-trip', () {
    final want = SyncMessage.decode(WantBlock('f', 2).encode()) as WantBlock;
    expect(want.path, equals('f'));
    expect(want.index, equals(2));

    final block =
        SyncMessage.decode(
              BlockPayload('f', 2, Uint8List.fromList([9, 9])).encode(),
            )
            as BlockPayload;
    expect(block.sealed, equals([9, 9]));
  });
}
