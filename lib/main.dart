import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'platform/background.dart';
import 'platform/desktop_lifecycle.dart';
import 'state/app_providers.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadInitialConfig();
  runApp(const ProviderScope(child: PointMachineApp()));
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final tray = await setupBackground(onQuit: () async {});
    if (tray != null) {
      attachDesktopLifecycle(tray, startHidden: args.contains('--hidden'));
    }
  });
}
