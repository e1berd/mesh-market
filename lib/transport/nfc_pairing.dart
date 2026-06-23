import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:nfc_manager/nfc_manager.dart';

import '../core/pairing.dart';

class NfcPairing {
  const NfcPairing();

  static Future<bool> isAvailable() async {
    try {
      return await NfcManager.instance.isAvailable();
    } on Object {
      return false;
    }
  }

  Future<PairingPayload> read() async {
    final completer = Completer<PairingPayload>();
    await NfcManager.instance.startSession(
      pollingOptions: NfcPollingOption.values.toSet(),
      onDiscovered: (tag) async {
        final payload = _extract(tag);
        if (payload != null && !completer.isCompleted) {
          completer.complete(payload);
        }
        await NfcManager.instance.stopSession();
      },
    );
    try {
      return await completer.future.timeout(const Duration(seconds: 30));
    } on Object {
      await NfcManager.instance.stopSession().catchError((_) {});
      rethrow;
    }
  }

  PairingPayload? _extract(NfcTag tag) {
    final message = Ndef.from(tag)?.cachedMessage;
    if (message == null) return null;
    for (final record in message.records) {
      final json = _json(_text(record.payload));
      if (json == null) continue;
      try {
        return PairingPayload.decode(json);
      } on Object {
        continue;
      }
    }
    return null;
  }

  String _text(Uint8List payload) => utf8.decode(payload, allowMalformed: true);

  String? _json(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    return text.substring(start, end + 1);
  }
}
