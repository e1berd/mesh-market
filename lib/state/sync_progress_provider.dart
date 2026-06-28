import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sync/sync_event.dart';

final syncProgressProvider =
    NotifierProvider<SyncProgressNotifier, Map<String, SyncProgress>>(
      SyncProgressNotifier.new,
    );

class SyncProgressNotifier extends Notifier<Map<String, SyncProgress>> {
  @override
  Map<String, SyncProgress> build() => const {};

  void update(SyncProgress progress) {
    final next = {...state};
    if (progress.active) {
      next[progress.key] = progress;
    } else {
      next.remove(progress.key);
    }
    state = next;
  }
}
