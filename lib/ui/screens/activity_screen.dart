import 'package:declar_ui/declar_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_core/m3e_core.dart';

import '../../i18n/strings.g.dart';
import '../../state/events_provider.dart';
import '../../state/peers_provider.dart';
import '../../sync/sync_event.dart';
import '../widgets/empty_state.dart';
import '../widgets/expressive.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(syncEventsProvider);
    final peers = ref.watch(pairedPeersProvider).value ?? const [];
    final names = {for (final peer in peers) peer.deviceId: peer.name};

    if (events.isEmpty) {
      return SafeArea(
        top: false,
        child: EmptyState(
          icon: Icons.sync_rounded,
          title: context.t.activity.empty,
          message: context.t.activity.emptyHint,
        ),
      );
    }

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
        child: ExpressiveReveal(
          child: M3ECardList(
            itemCount: events.length,
            itemBuilder: (ctx, i) => _row(context, events[i], names),
            outerRadius: 32,
            innerRadius: 12,
            gap: 0,
            color: context.colors.surfaceContainerHigh,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, SyncEvent event, Map<String, String> names) {
    final colors = context.colors;
    final (icon, background, foreground) = _appearance(context, event.kind);
    return Row(
      children: [
        ExpressiveIconContainer(
          icon: icon,
          color: background,
          foregroundColor: foreground,
          size: 44,
          radius: 14,
        ).padding(right: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Text(_title(context, event.kind))
                  .size(14)
                  .weight(.w700)
                  .color(colors.onSurface),
              Text(_subtitle(event, names))
                  .size(12)
                  .color(colors.onSurfaceVariant)
                  .maxLines(1)
                  .overflow(.ellipsis),
            ],
          ),
        ),
        Text(_time(event.at)).size(11).weight(.w600).color(colors.onSurfaceVariant),
      ],
    );
  }

  String _title(BuildContext context, SyncEventKind kind) => switch (kind) {
        SyncEventKind.connected => context.t.activity.eventConnected,
        SyncEventKind.disconnected => context.t.activity.eventDisconnected,
        SyncEventKind.received => context.t.activity.eventReceived,
        SyncEventKind.conflict => context.t.activity.eventConflict,
      };

  String _subtitle(SyncEvent event, Map<String, String> names) {
    final peer = event.peerId == null ? null : names[event.peerId] ?? event.peerId;
    return event.path ?? peer ?? '';
  }

  String _time(DateTime at) {
    final local = at.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  (IconData, Color, Color) _appearance(BuildContext context, SyncEventKind kind) {
    final colors = context.colors;
    return switch (kind) {
      SyncEventKind.received => (
          Icons.download_done_rounded,
          colors.primaryContainer,
          colors.onPrimaryContainer,
        ),
      SyncEventKind.conflict => (
          Icons.warning_amber_rounded,
          colors.errorContainer,
          colors.onErrorContainer,
        ),
      SyncEventKind.connected => (
          Icons.link_rounded,
          colors.tertiaryContainer,
          colors.onTertiaryContainer,
        ),
      SyncEventKind.disconnected => (
          Icons.link_off_rounded,
          colors.surfaceContainerHighest,
          colors.onSurfaceVariant,
        ),
    };
  }
}
