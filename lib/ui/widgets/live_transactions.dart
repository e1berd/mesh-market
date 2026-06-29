import 'package:declar_ui/declar_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/strings.g.dart';
import '../../state/folders_provider.dart';
import '../../state/identity_provider.dart';
import '../../state/peers_provider.dart';
import '../../state/sync_progress_provider.dart';
import '../../sync/sync_event.dart';
import 'expressive.dart';

const _liveMaxWidth = 960.0;

class LiveTransactions extends ConsumerWidget {
  const LiveTransactions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(syncProgressProvider);
    if (progress.isEmpty) return const SizedBox.shrink();

    final entries = progress.values.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final peers = ref.watch(pairedPeersProvider).value ?? const [];
    final names = {for (final peer in peers) peer.deviceId: peer.name};
    final folders = ref.watch(foldersProvider).value ?? const [];
    final labels = {for (final folder in folders) folder.id: folder.label};
    final you = ref.watch(deviceNameProvider).value ?? context.t.activity.you;

    return Padding(
      padding: expressiveScreenPadding(context).copyWith(top: 0, bottom: 12),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _liveMaxWidth),
          child: ExpressiveSection(
            title: context.t.activity.liveTitle,
            children: [
              for (final entry in entries)
                _TransactionRow(
                  progress: entry,
                  peerName: names[entry.peerId] ?? entry.peerId,
                  folderLabel: labels[entry.folderId] ?? entry.folderId,
                  you: you,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.progress,
    required this.peerName,
    required this.folderLabel,
    required this.you,
  });

  final SyncProgress progress;
  final String peerName;
  final String folderLabel;
  final String you;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final incoming = progress.direction == SyncDirection.incoming;
    final complete = progress.total > 0 && progress.done >= progress.total;
    final from = incoming ? peerName : you;
    final to = incoming ? you : peerName;

    final (icon, background, foreground) = complete
        ? (
            Icons.check_circle_rounded,
            colors.primaryContainer,
            colors.onPrimaryContainer,
          )
        : incoming
        ? (
            Icons.south_rounded,
            colors.secondaryContainer,
            colors.onSecondaryContainer,
          )
        : (
            Icons.north_rounded,
            colors.tertiaryContainer,
            colors.onTertiaryContainer,
          );

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          ExpressiveIconContainer(
            icon: icon,
            color: background,
            foregroundColor: foreground,
            size: 52,
            radius: 18,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                _Route(from: from, to: to),
                const SizedBox(height: 4),
                Text(folderLabel)
                    .size(13)
                    .color(colors.onSurfaceVariant)
                    .maxLines(1)
                    .overflow(.ellipsis),
                const SizedBox(height: 10),
                if (complete)
                  ExpressiveStatusPill(
                    label: context.t.activity.liveComplete,
                    icon: Icons.done_all_rounded,
                    color: colors.primaryContainer,
                    foregroundColor: colors.onPrimaryContainer,
                  )
                else
                  _Progress(progress: progress),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Route extends StatelessWidget {
  const _Route({required this.from, required this.to});

  final String from;
  final String to;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Flexible(
          child: Text(from)
              .size(15)
              .weight(.w800)
              .color(colors.onSurface)
              .maxLines(1)
              .overflow(.ellipsis),
        ),
        const SizedBox(width: 8),
        Icon(Icons.arrow_forward_rounded, size: 18, color: colors.primary),
        const SizedBox(width: 8),
        Flexible(
          child: Text(to)
              .size(15)
              .weight(.w800)
              .color(colors.onSurface)
              .maxLines(1)
              .overflow(.ellipsis),
        ),
      ],
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.progress});

  final SyncProgress progress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final known = progress.total > 0;
    final label = known
        ? context.t.activity.liveFiles(
            done: progress.done,
            total: progress.total,
          )
        : context.t.activity.livePreparing;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Text(label).size(12).weight(.w700).color(colors.onSurfaceVariant),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: known ? progress.done / progress.total : null,
          minHeight: 8,
          borderRadius: BorderRadius.circular(100),
          backgroundColor: colors.surfaceContainerHighest,
          color: colors.primary,
        ),
      ],
    );
  }
}
