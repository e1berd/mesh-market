import 'dart:io';

import 'package:pm_offline/pm_offline.dart';

export 'package:pm_offline/pm_offline.dart' show HotspotCredentials;

class HotspotController {
  const HotspotController();

  static Future<bool> isSupported() async {
    if (!Platform.isAndroid) return false;
    return const SoftApChannel().isSupported();
  }

  Future<HotspotCredentials?> start() => const SoftApChannel().start();

  Future<void> stop() => const SoftApChannel().stop();
}
