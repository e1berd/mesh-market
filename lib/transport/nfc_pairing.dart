import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';

import '../core/pairing.dart';

class NfcPairing {
  const NfcPairing();

  static const mimeType =
      'application/vnd.tech.hammerhead.mesh-market.pairing+json';
  static const _channel = MethodChannel(
    'tech.hammerhead.mesh_market/nfc_pairing',
  );

  static Future<bool> isAvailable() async {
    try {
      return await NfcManager.instance.isAvailable();
    } on Object {
      return false;
    }
  }

  Future<PairingPayload> shareAndRead(
    PairingPayload self, {
    Future<void>? cancelSignal,
  }) async {
    await _popHceReceived().catchError((_) => null);
    await startPassive(self).catchError((_) => false);
    await _startNdefPush(self).catchError((_) => false);
    try {
      return await Future.any([
        _readAndWrite(self),
        _waitForHceReceived(),
        if (cancelSignal != null)
          cancelSignal.then<PairingPayload>(
            (_) => throw const NfcPairingCanceled(),
          ),
      ]);
    } finally {
      await cancelActive();
    }
  }

  Future<void> cancelActive() async {
    await _stopNdefPush().catchError((_) {});
    await _stopHce().catchError((_) {});
    await NfcManager.instance.stopSession().catchError((_) {});
  }

  Future<bool> startPassive(PairingPayload self) async {
    await _popHceReceived().catchError((_) => null);
    return _startHce(self);
  }

  Future<void> stopPassive() => _stopHce();

  Future<PairingPayload?> takePassiveReceived() async {
    final raw = await _popHceReceived().catchError((_) => null);
    if (raw == null || raw.isEmpty) return null;
    return PairingPayload.decode(raw);
  }

  Future<PairingPayload> read() async {
    return _readAndWrite(null);
  }

  Future<PairingPayload> _readAndWrite(PairingPayload? self) async {
    final completer = Completer<PairingPayload>();
    await NfcManager.instance.startSession(
      pollingOptions: const {NfcPollingOption.iso14443},
      onDiscovered: (tag) async {
        final payload = await _readTag(tag);
        if (payload != null && !completer.isCompleted) {
          if (self != null) await _writeHce(tag, self);
          completer.complete(payload);
          await NfcManager.instance.stopSession();
        }
      },
    );
    try {
      return await completer.future.timeout(const Duration(seconds: 30));
    } on Object {
      await NfcManager.instance.stopSession().catchError((_) {});
      rethrow;
    }
  }

  Future<bool> _startNdefPush(PairingPayload payload) async {
    final ok = await _channel.invokeMethod<bool>('startNdefPush', {
      'mimeType': mimeType,
      'payload': payload.encode(),
    });
    return ok ?? false;
  }

  Future<void> _stopNdefPush() => _channel.invokeMethod<void>('stopNdefPush');

  Future<bool> _startHce(PairingPayload payload) async {
    final ok = await _channel.invokeMethod<bool>('startHce', {
      'payload': payload.encode(),
    });
    return ok ?? false;
  }

  Future<String?> _popHceReceived() =>
      _channel.invokeMethod<String>('popHceReceived');

  Future<void> _stopHce() => _channel.invokeMethod<void>('stopHce');

  Future<PairingPayload> _waitForHceReceived() async {
    final started = DateTime.now();
    while (DateTime.now().difference(started) < const Duration(seconds: 30)) {
      final raw = await _popHceReceived().catchError((_) => null);
      if (raw != null && raw.isNotEmpty) return PairingPayload.decode(raw);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    throw TimeoutException('No NFC peer payload received');
  }

  Future<PairingPayload?> _readTag(NfcTag tag) async {
    final hcePayload = await _readHce(tag);
    if (hcePayload != null) return hcePayload;
    return _extractNdef(tag);
  }

  Future<PairingPayload?> _readHce(NfcTag tag) async {
    final isoDep = IsoDep.from(tag);
    if (isoDep == null) return null;
    try {
      final selected = await isoDep.transceive(data: _selectAidApdu());
      if (!_isSuccess(selected)) return null;

      final info = await isoDep.transceive(
        data: Uint8List.fromList([0x80, 0x10, 0, 0, 4]),
      );
      if (!_isSuccess(info) || info.length < 6) return null;
      final length =
          (info[0] << 24) | (info[1] << 16) | (info[2] << 8) | info[3];
      if (length <= 0 || length > 4096) return null;

      final bytes = <int>[];
      while (bytes.length < length) {
        final offset = bytes.length;
        final chunkSize = (length - offset).clamp(1, 240);
        final chunk = await isoDep.transceive(
          data: Uint8List.fromList([
            0x80,
            0x20,
            (offset >> 8) & 0xff,
            offset & 0xff,
            chunkSize,
          ]),
        );
        if (!_isSuccess(chunk) || chunk.length <= 2) return null;
        bytes.addAll(chunk.take(chunk.length - 2));
      }
      return PairingPayload.decode(utf8.decode(bytes));
    } on Object {
      return null;
    }
  }

  Future<void> _writeHce(NfcTag tag, PairingPayload payload) async {
    final isoDep = IsoDep.from(tag);
    if (isoDep == null) return;
    try {
      final selected = await isoDep.transceive(data: _selectAidApdu());
      if (!_isSuccess(selected)) return;

      final bytes = utf8.encode(payload.encode());
      var offset = 0;
      while (offset < bytes.length) {
        final end = offset + 220 > bytes.length ? bytes.length : offset + 220;
        final chunk = bytes.sublist(offset, end);
        final response = await isoDep.transceive(
          data: Uint8List.fromList([
            0x80,
            0x30,
            (offset >> 8) & 0xff,
            offset & 0xff,
            chunk.length,
            ...chunk,
          ]),
        );
        if (!_isSuccess(response)) return;
        offset = end;
      }

      await isoDep.transceive(data: Uint8List.fromList([0x80, 0x40, 0, 0, 0]));
    } on Object {
      return;
    }
  }

  Uint8List _selectAidApdu() {
    const aid = [0xf0, 0x48, 0x4d, 0x50, 0x41, 0x49, 0x52];
    return Uint8List.fromList([
      0x00,
      0xa4,
      0x04,
      0x00,
      aid.length,
      ...aid,
      0x00,
    ]);
  }

  bool _isSuccess(Uint8List response) =>
      response.length >= 2 &&
      response[response.length - 2] == 0x90 &&
      response[response.length - 1] == 0x00;

  PairingPayload? _extractNdef(NfcTag tag) {
    final message = Ndef.from(tag)?.cachedMessage;
    if (message == null) return null;
    for (final record in message.records) {
      final json = _recordJson(record);
      if (json == null) continue;
      try {
        return PairingPayload.decode(json);
      } on Object {
        continue;
      }
    }
    return null;
  }

  String? _recordJson(NdefRecord record) {
    if (_isPairingMime(record)) {
      return _text(record.payload);
    }
    return _json(_text(record.payload));
  }

  bool _isPairingMime(NdefRecord record) {
    if (record.typeNameFormat != NdefTypeNameFormat.media) return false;
    final type = ascii.decode(record.type, allowInvalid: true).toLowerCase();
    return type == mimeType;
  }

  String _text(Uint8List payload) => utf8.decode(payload, allowMalformed: true);

  String? _json(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    return text.substring(start, end + 1);
  }
}

class NfcPairingCanceled implements Exception {
  const NfcPairingCanceled();
}
