import 'dart:io';

import 'desktop_tray.dart';

bool get _isDesktop =>
    Platform.isLinux || Platform.isMacOS || Platform.isWindows;

Future<DesktopTray?> setupBackground({
  required Future<void> Function() onQuit,
}) async {
  if (!_isDesktop) return null;
  final tray = DesktopTray(
    iconPath: Platform.isWindows ? 'assets/tray.ico' : 'assets/tray.png',
    onQuit: onQuit,
  );
  try {
    await tray.setup();
    return tray;
  } on Object {
    return null;
  }
}
