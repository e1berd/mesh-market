import 'dart:convert';

import 'package:cryptography/cryptography.dart';

Future<String> pairingCode(String a, String b) async {
  final ordered = ([a, b]..sort()).join('|');
  final digest = await Sha256().hash(utf8.encode(ordered));
  final value = (digest.bytes[0] << 16 | digest.bytes[1] << 8 | digest.bytes[2]) %
      1000000;
  return value.toString().padLeft(6, '0');
}
