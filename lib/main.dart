import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'platform/background.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupBackground(onQuit: () async {});
  runApp(const ProviderScope(child: PointMachineApp()));
}
