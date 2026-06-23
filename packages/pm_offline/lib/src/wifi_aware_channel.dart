import 'package:flutter/services.dart';

import 'offline_endpoint.dart';

class WifiAwareChannel {
  const WifiAwareChannel();

  static const _channel = MethodChannel('pm_offline/wifi_aware');

  Future<bool> isSupported() async {
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> start({required String deviceId, required int syncPort}) async {
    await _channel.invokeMethod('start', {
      'deviceId': deviceId,
      'syncPort': syncPort,
    });
  }

  Future<OfflineEndpoint?> resolve(String peerId) async {
    final map = await _channel.invokeMethod<Map<Object?, Object?>>('resolve', {
      'peerId': peerId,
    });
    return OfflineEndpoint.fromMap(map);
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
