import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sync/sync_event.dart';

final syncEventsProvider =
    NotifierProvider<SyncEventsNotifier, List<SyncEvent>>(SyncEventsNotifier.new);

class SyncEventsNotifier extends Notifier<List<SyncEvent>> {
  static const _limit = 100;

  @override
  List<SyncEvent> build() => const [];

  void add(SyncEvent event) {
    final next = [event, ...state];
    state = next.length > _limit ? next.sublist(0, _limit) : next;
  }
}
