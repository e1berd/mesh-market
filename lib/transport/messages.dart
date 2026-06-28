import 'dart:typed_data';

import 'package:cbor/cbor.dart';

import '../sync/index.dart';

sealed class SyncMessage {
  const SyncMessage();

  String get type;
  Map<String, Object?> fields();

  Uint8List encode() =>
      Uint8List.fromList(cbor.encode(CborValue({'t': type, ...fields()})));

  static SyncMessage decode(Uint8List bytes) {
    final map = (cbor.decode(bytes).toObject()! as Map).cast<String, Object?>();
    return switch (map['t']) {
      'open' => OpenLink(map['id']! as String, map['folder']! as String),
      'hello' => Hello(map['id']! as String, _bytes(map['sig'])),
      'index' => IndexSnapshot([
        for (final entry in map['entries']! as List)
          IndexEntry.fromMap((entry as Map).cast<String, Object?>()),
      ]),
      'want' => WantBlock(map['path']! as String, map['i']! as int),
      'block' => BlockPayload(
        map['path']! as String,
        map['i']! as int,
        _bytes(map['d']),
      ),
      'progress' => Progress(map['d']! as int, map['n']! as int),
      'bye' => const Bye(),
      _ => throw FormatException('unknown message type: ${map['t']}'),
    };
  }

  static Uint8List _bytes(Object? value) =>
      Uint8List.fromList((value! as List).cast<int>());
}

final class OpenLink extends SyncMessage {
  const OpenLink(this.deviceId, this.folderId);

  final String deviceId;
  final String folderId;

  @override
  String get type => 'open';

  @override
  Map<String, Object?> fields() => {'id': deviceId, 'folder': folderId};
}

final class Hello extends SyncMessage {
  Hello(this.deviceId, this.signature);

  final String deviceId;
  final Uint8List signature;

  @override
  String get type => 'hello';

  @override
  Map<String, Object?> fields() => {'id': deviceId, 'sig': signature};
}

final class IndexSnapshot extends SyncMessage {
  IndexSnapshot(this.entries);

  final List<IndexEntry> entries;

  @override
  String get type => 'index';

  @override
  Map<String, Object?> fields() => {
    'entries': [for (final entry in entries) entry.toMap()],
  };
}

final class WantBlock extends SyncMessage {
  WantBlock(this.path, this.index);

  final String path;
  final int index;

  @override
  String get type => 'want';

  @override
  Map<String, Object?> fields() => {'path': path, 'i': index};
}

final class BlockPayload extends SyncMessage {
  BlockPayload(this.path, this.index, this.sealed);

  final String path;
  final int index;
  final Uint8List sealed;

  @override
  String get type => 'block';

  @override
  Map<String, Object?> fields() => {'path': path, 'i': index, 'd': sealed};
}

final class Progress extends SyncMessage {
  const Progress(this.done, this.total);

  final int done;
  final int total;

  @override
  String get type => 'progress';

  @override
  Map<String, Object?> fields() => {'d': done, 'n': total};
}

final class Bye extends SyncMessage {
  const Bye();

  @override
  String get type => 'bye';

  @override
  Map<String, Object?> fields() => const {};
}
