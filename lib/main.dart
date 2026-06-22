import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'platform/background.dart';
import 'platform/desktop_lifecycle.dart';
import 'platform/desktop_tray.dart';
import 'state/app_providers.dart';

DesktopTray? _desktopTray;
AppLifecycleListener? _desktopLifecycle;

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadInitialConfig();
  runApp(const ProviderScope(child: PointMachineApp()));
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await _desktopTray?.dispose();
    final tray = await setupBackground(onQuit: () async {});
    if (tray != null) {
      _desktopLifecycle?.dispose();
      _desktopLifecycle = attachDesktopLifecycle(
        tray,
        startHidden: args.contains('--hidden'),
      );
      _desktopTray = tray;
    }
  });
}
