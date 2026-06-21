import 'package:declar_ui/declar_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_core/m3e_core.dart';

import '../../i18n/strings.g.dart';
import '../../state/app_providers.dart';
import '../../state/events_provider.dart';
import '../../state/peers_provider.dart';
import '../../state/sync_schedule_provider.dart';
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

    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          const ExpressiveReveal(child: _ScheduleControls()),
          Expanded(
            child: events.isEmpty
                ? EmptyState(
                    icon: Icons.sync_rounded,
                    title: context.t.activity.empty,
                    message: context.t.activity.emptyHint,
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 96),
                    child: ExpressiveReveal(
                      child: M3ECardList(
                        itemCount: events.length,
                        itemBuilder: (ctx, i) => _row(context, events[i], names),
                        outerRadius: 32,
                        innerRadius: 12,
                        gap: 0,
                        color: context.colors.surfaceContainerHigh,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      ),
                    ),
                  ),
          ),
        ],
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

String _formatMinutes(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
    '${(minutes % 60).toString().padLeft(2, '0')}';

class _ScheduleControls extends ConsumerWidget {
  const _ScheduleControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final config = ref.watch(configProvider);
    final active = ref.watch(syncActiveProvider).value ?? false;
    final notifier = ref.read(configProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Material(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(context.t.schedule.title).size(18).weight(.w800),
              ),
              _statusPill(context, active),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(context.t.schedule.syncNow),
            subtitle: Text(context.t.schedule.syncNowHint),
            value: config.syncNow,
            onChanged: notifier.setSyncNow,
          ),
          const Divider(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(context.t.schedule.scheduleTitle),
            subtitle: Text(context.t.schedule.scheduleHint),
            value: config.scheduleEnabled,
            onChanged: notifier.setScheduleEnabled,
          ),
          if (config.scheduleEnabled)
            Row(
              children: [
                Expanded(
                  child: _timeField(context, ref, context.t.schedule.from,
                      config.scheduleStart, start: true),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _timeField(context, ref, context.t.schedule.to,
                      config.scheduleEnd, start: false),
                ),
              ],
            ).padding(top: 8, bottom: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusPill(BuildContext context, bool active) {
    final colors = context.colors;
    final background =
        active ? colors.primaryContainer : colors.surfaceContainerHighest;
    final foreground =
        active ? colors.onPrimaryContainer : colors.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: .min,
        children: [
          Icon(active ? Icons.sync_rounded : Icons.pause_rounded,
              size: 16, color: foreground),
          const SizedBox(width: 6),
          Text(active ? context.t.schedule.active : context.t.schedule.paused)
              .size(12)
              .weight(.w700)
              .color(foreground),
        ],
      ),
    );
  }

  Widget _timeField(
    BuildContext context,
    WidgetRef ref,
    String label,
    int minutes, {
    required bool start,
  }) {
    final colors = context.colors;
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
        );
        if (picked == null) return;
        final config = ref.read(configProvider);
        final value = picked.hour * 60 + picked.minute;
        ref.read(configProvider.notifier).setSchedule(
              start ? value : config.scheduleStart,
              start ? config.scheduleEnd : value,
            );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Text(label).size(11).weight(.w600).color(colors.onSurfaceVariant),
            const SizedBox(height: 2),
            Text(_formatMinutes(minutes))
                .size(22)
                .weight(.w800)
                .color(colors.onSurface),
          ],
        ),
      ),
    );
  }
}
