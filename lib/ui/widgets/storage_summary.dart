import 'package:declar_ui/declar_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/byte_size.dart';
import '../../core/models.dart';
import '../../i18n/strings.g.dart';
import '../../state/folders_provider.dart';
import '../../state/storage_provider.dart';
import 'expressive.dart';

const _byteUnits = ['B', 'KB', 'MB', 'GB', 'TB'];

class StorageSummary extends ConsumerWidget {
  const StorageSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final total = ref.watch(totalStorageProvider);
    final folders = ref.watch(foldersProvider).value ?? const <FolderConfig>[];

    return AnimatedContainer(
      duration: expressiveFastDuration,
      curve: expressiveCurve,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          ExpressiveIconContainer(
            icon: Icons.cloud_sync_rounded,
            color: colors.primary,
            foregroundColor: colors.onPrimary,
            size: 56,
            radius: 20,
          ).padding(right: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(context.t.devices.storageTitle)
                    .size(12)
                    .weight(.w800)
                    .letterSpacing(0)
                    .color(colors.onPrimaryContainer.withValues(alpha: .8)),
                const SizedBox(height: 2),
                ExpressiveSwitcher(
                  duration: expressiveFastDuration,
                  child: Text(
                    _label(total),
                    key: ValueKey(total.value ?? -1),
                  ).size(30).weight(.w800).color(colors.onPrimaryContainer),
                ),
              ],
            ),
          ),
          _FoldersPill(count: folders.length),
        ],
      ),
    );
  }

  String _label(AsyncValue<int> total) => total.when(
    data: (bytes) => formatBytes(bytes, _byteUnits),
    loading: () => '…',
    error: (_, _) => '—',
  );
}

class _FoldersPill extends StatelessWidget {
  const _FoldersPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colors.onPrimaryContainer.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: .min,
        children: [
          Icon(Icons.folder_rounded, size: 16, color: colors.onPrimaryContainer),
          const SizedBox(width: 6),
          Text(context.t.devices.foldersCount(n: count))
              .size(12)
              .weight(.w800)
              .color(colors.onPrimaryContainer),
        ],
      ),
    );
  }
}
