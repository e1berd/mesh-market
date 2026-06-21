import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config.dart';
import 'app_providers.dart';

bool syncWindowActive(AppConfig config, DateTime now) {
  if (config.syncNow) return true;
  if (!config.scheduleEnabled) return false;
  final minutes = now.hour * 60 + now.minute;
  final start = config.scheduleStart;
  final end = config.scheduleEnd;
  return start <= end
      ? minutes >= start && minutes < end
      : minutes >= start || minutes < end;
}

final syncActiveProvider = StreamProvider<bool>((ref) async* {
  final config = ref.watch(configProvider);
  yield syncWindowActive(config, DateTime.now());
  yield* Stream.periodic(
    const Duration(seconds: 20),
    (_) => syncWindowActive(config, DateTime.now()),
  );
});
