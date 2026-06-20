import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'state/app_providers.dart';
import 'ui/home_shell.dart';
import 'ui/theme.dart';

class PointMachineApp extends ConsumerWidget {
  const PointMachineApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(configProvider.select((c) => c.themeMode));
    return DynamicColorBuilder(
      builder: (light, dark) => MaterialApp(
        title: 'point-machine',
        theme: pointTheme(.light, light),
        darkTheme: pointTheme(.dark, dark),
        themeMode: mode,
        debugShowCheckedModeBanner: false,
        home: const HomeShell(),
      ),
    );
  }
}
