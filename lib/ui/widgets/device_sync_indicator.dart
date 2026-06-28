import 'dart:async';

import 'package:declar_ui/declar_ui.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/byte_size.dart';
import '../../i18n/strings.g.dart';
import '../../state/storage_provider.dart';
import '../../state/sync_progress_provider.dart';
import '../../state/sync_status_provider.dart';
import 'expressive.dart';

const _byteUnits = ['B', 'KB', 'MB', 'GB', 'TB'];
const _activityWindow = Duration(seconds: 6);

class DeviceSyncIndicator extends ConsumerStatefulWidget {
  const DeviceSyncIndicator({super.key, required this.deviceId});

  final String deviceId;

  @override
  ConsumerState<DeviceSyncIndicator> createState() =>
      _DeviceSyncIndicatorState();
}

class _DeviceSyncIndicatorState extends ConsumerState<DeviceSyncIndicator> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _scheduleExpiry(List<DateTime?> stamps, DateTime now) {
    _timer?.cancel();
    Duration? soonest;
    for (final stamp in stamps) {
      if (stamp == null) continue;
      final remaining = _activityWindow - now.difference(stamp);
      if (remaining > Duration.zero &&
          (soonest == null || remaining < soonest)) {
        soonest = remaining;
      }
    }
    if (soonest != null) {
      _timer = Timer(soonest, () {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final sync = ref.watch(deviceSyncProvider(widget.deviceId));
    final storage = ref.watch(deviceStorageProvider(widget.deviceId));
    final progress = ref.watch(syncProgressProvider);

    var done = 0;
    var total = 0;
    for (final entry in progress.values) {
      if (entry.peerId == widget.deviceId) {
        done += entry.done;
        total += entry.total;
      }
    }
    final transferring = total > 0 && done < total;

    final now = DateTime.now();
    bool recent(DateTime? stamp) =>
        stamp != null && now.difference(stamp) < _activityWindow;

    final receiving = recent(sync.lastReceived);
    final connecting = recent(sync.lastConnecting);
    final syncing = transferring || receiving || connecting;
    final conflict = !syncing && recent(sync.lastConflict);

    final label = transferring
        ? context.t.devices.filesProgress(done: done, total: total)
        : connecting
        ? context.t.devices.connecting
        : context.t.devices.syncing;

    _scheduleExpiry(
      [sync.lastReceived, sync.lastConnecting, sync.lastConflict],
      now,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Row(
            children: [
              _StorageStat(value: storage),
              const Spacer(),
              ExpressiveSwitcher(
                duration: expressiveFastDuration,
                child: syncing
                    ? _StatusPill(
                        key: const ValueKey('syncing'),
                        label: label,
                        icon: Icons.sync_rounded,
                        container: colors.primaryContainer,
                        foreground: colors.onPrimaryContainer,
                        busy: true,
                      )
                    : conflict
                    ? _StatusPill(
                        key: const ValueKey('conflict'),
                        label: context.t.devices.conflict,
                        icon: Icons.warning_amber_rounded,
                        container: colors.errorContainer,
                        foreground: colors.onErrorContainer,
                        busy: false,
                      )
                    : const SizedBox.shrink(key: ValueKey('idle')),
              ),
            ],
          ),
          AnimatedSize(
            duration: expressiveFastDuration,
            curve: expressiveCurve,
            alignment: Alignment.topCenter,
            child: syncing
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: LinearProgressIndicator(
                      value: transferring ? done / total : null,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(100),
                      backgroundColor: colors.surfaceContainerHighest,
                      color: colors.primary,
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    super.key,
    required this.label,
    required this.icon,
    required this.container,
    required this.foreground,
    required this.busy,
  });

  final String label;
  final IconData icon;
  final Color container;
  final Color foreground;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: container,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: .min,
        children: [
          busy
              ? SizedBox.square(
                  dimension: 13,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: ExpressiveLoadingIndicator(color: foreground),
                  ),
                )
              : Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 10),
          Text(label).size(12).weight(.w800).color(foreground),
        ],
      ),
    );
  }
}

class _StorageStat extends StatelessWidget {
  const _StorageStat({required this.value});

  final AsyncValue<int> value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: .min,
      children: [
        Icon(Icons.sd_storage_rounded, size: 16, color: colors.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          value.when(
            data: (bytes) => formatBytes(bytes, _byteUnits),
            loading: () => '…',
            error: (_, _) => '—',
          ),
        ).size(13).weight(.w700).color(colors.onSurface),
      ],
    );
  }
}
