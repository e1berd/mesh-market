import 'package:flutter/services.dart';

class MultipeerEvent {
  const MultipeerEvent({
    required this.type,
    required this.sessionId,
    this.peerId,
    this.folderId,
    this.data,
  });

  final String type;
  final String sessionId;
  final String? peerId;
  final String? folderId;
  final Uint8List? data;

  static MultipeerEvent fromMap(Map<Object?, Object?> map) => MultipeerEvent(
    type: map['type'] as String? ?? 'unknown',
    sessionId: map['sessionId'] as String? ?? '',
    peerId: map['peerId'] as String?,
    folderId: map['folderId'] as String?,
    data: map['data'] as Uint8List?,
  );
}

class MultipeerChannel {
  const MultipeerChannel();

  static const _channel = MethodChannel('pm_offline/multipeer');
  static const _events = EventChannel('pm_offline/multipeer/events');

  Stream<MultipeerEvent> get events => _events
      .receiveBroadcastStream()
      .map((event) => MultipeerEvent.fromMap(event as Map<Object?, Object?>));

  Future<bool> isSupported() async {
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> start({required String deviceId}) async {
    await _channel.invokeMethod('start', {'deviceId': deviceId});
  }

  Future<String?> open({
    required String peerId,
    required String folderId,
  }) async {
    return _channel.invokeMethod<String>('open', {
      'peerId': peerId,
      'folderId': folderId,
    });
  }

  Future<void> send({
    required String sessionId,
    required Uint8List data,
  }) async {
    await _channel.invokeMethod('send', {'sessionId': sessionId, 'data': data});
  }

  Future<void> closeSession(String sessionId) async {
    try {
      await _channel.invokeMethod('close', {'sessionId': sessionId});
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
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
