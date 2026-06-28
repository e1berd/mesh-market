import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sync/sync_event.dart';
import 'events_provider.dart';

class DeviceSync {
  const DeviceSync({this.lastConnecting, this.lastReceived, this.lastConflict});

  final DateTime? lastConnecting;
  final DateTime? lastReceived;
  final DateTime? lastConflict;
}

final deviceSyncProvider = Provider.family<DeviceSync, String>((ref, deviceId) {
  final events = ref.watch(syncEventsProvider);
  DateTime? connecting;
  DateTime? received;
  DateTime? conflict;

  for (final event in events) {
    if (event.peerId != deviceId) continue;
    switch (event.kind) {
      case SyncEventKind.connecting:
        connecting ??= event.at;
      case SyncEventKind.received:
        received ??= event.at;
      case SyncEventKind.conflict:
        conflict ??= event.at;
      case SyncEventKind.connected:
      case SyncEventKind.disconnected:
        break;
    }
    if (connecting != null && received != null && conflict != null) break;
  }

  return DeviceSync(
    lastConnecting: connecting,
    lastReceived: received,
    lastConflict: conflict,
  );
});
