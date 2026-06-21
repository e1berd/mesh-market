import 'dart:isolate';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../crypto/codec.dart';

const blockSize = 128 * 1024;

int blockCountFor(int length) => length == 0 ? 0 : (length + blockSize - 1) ~/ blockSize;

Future<List<String>> hashBlocks(Uint8List data) => Isolate.run(() => _hash(data));

Future<String> hashBytes(List<int> bytes) async =>
    hexEncode((await Sha256().hash(bytes)).bytes);

Future<List<String>> _hash(Uint8List data) async {
  final sha256 = Sha256();
  final hashes = <String>[];
  for (var offset = 0; offset < data.length; offset += blockSize) {
    final end = offset + blockSize < data.length ? offset + blockSize : data.length;
    final digest = await sha256.hash(data.sublist(offset, end));
    hashes.add(hexEncode(digest.bytes));
  }
  return hashes;
}
