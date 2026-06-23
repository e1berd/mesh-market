import 'dart:io';

import 'package:pm_offline/pm_offline.dart';

import 'ip_link_bringup.dart';
import 'peer_link.dart';

class WifiAwareTransport {
  WifiAwareTransport({
    required this.deviceId,
    required this.bringup,
    required this.syncPort,
  });

  final String deviceId;
  final IpLinkBringup bringup;
  final int Function() syncPort;

  final _channel = const WifiAwareChannel();
  bool _started = false;

  static Future<bool> isSupported() async {
    if (!Platform.isAndroid) return false;
    return const WifiAwareChannel().isSupported();
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;
    await _channel.start(deviceId: deviceId, syncPort: syncPort());
  }

  Future<PeerLink> open({
    required String peerId,
    required String folderId,
  }) async {
    await start();
    final endpoint = await _channel.resolve(peerId);
    if (endpoint == null) {
      throw StateError('wifi-aware: peer $peerId unreachable');
    }
    return bringup.connect(
      host: endpoint.host,
      port: endpoint.port,
      peerId: peerId,
      folderId: folderId,
    );
  }

  Future<void> stop() async {
    if (!_started) return;
    _started = false;
    await _channel.stop();
  }
}
