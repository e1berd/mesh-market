import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../crypto/codec.dart';

Future<String> infohashFor(List<int> swarmSecret) async {
  final digest = await Sha256().hash(swarmSecret);
  return hexEncode(digest.bytes.sublist(0, 20));
}

Uint8List newSwarmSecret() {
  final random = Random.secure();
  return Uint8List.fromList([for (var i = 0; i < 32; i++) random.nextInt(256)]);
}
