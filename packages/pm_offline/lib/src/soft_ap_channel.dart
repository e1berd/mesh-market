import 'package:flutter/services.dart';

class HotspotCredentials {
  const HotspotCredentials({required this.ssid, required this.passphrase});

  final String ssid;
  final String passphrase;

  static HotspotCredentials? fromMap(Map<Object?, Object?>? map) {
    if (map == null) return null;
    final ssid = map['ssid'] as String?;
    if (ssid == null) return null;
    return HotspotCredentials(
      ssid: ssid,
      passphrase: map['passphrase'] as String? ?? '',
    );
  }
}

class SoftApChannel {
  const SoftApChannel();

  static const _channel = MethodChannel('pm_offline/soft_ap');

  Future<bool> isSupported() async {
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<HotspotCredentials?> start() async {
    final map = await _channel.invokeMethod<Map<Object?, Object?>>('start');
    return HotspotCredentials.fromMap(map);
  }

  Future<void> stop() async {
    try {
      await _channel.invokeMethod('stop');
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }
}
