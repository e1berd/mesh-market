import 'package:declar_ui/declar_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_core/m3e_core.dart';

import '../../core/models.dart';
import '../../i18n/strings.g.dart';
import '../../state/folders_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/expressive.dart';

class FoldersScreen extends ConsumerWidget {
  const FoldersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(foldersProvider);
    final colors = context.colors;

    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          ExpressiveReveal(
            child: M3EButton.icon(
              onPressed: () => _add(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: Text(context.t.folders.add),
              size: .md,
            ).padding(horizontal: 16, top: 12, bottom: 8),
          ),
          Expanded(
            child: ExpressiveSwitcher(
              child: folders.when(
                loading: () => const Center(
                  key: ValueKey('folders-loading'),
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => EmptyState(
                  key: const ValueKey('folders-error'),
                  icon: Icons.error_outline_rounded,
                  title: context.t.folders.errorLoad,
                  message: '$error',
                ),
                data: (list) => list.isEmpty
                    ? EmptyState(
                        key: const ValueKey('folders-empty'),
                        icon: Icons.create_new_folder_rounded,
                        title: context.t.folders.empty,
                        message: context.t.folders.emptyHint,
                      )
                    : M3EDismissibleCardList(
                        key: const ValueKey('folders-list'),
                        itemCount: list.length,
                        itemBuilder: (ctx, i) => _FolderTile(
                          folder: list[i],
                          onRemove: () => ref
                              .read(foldersProvider.notifier)
                              .remove(list[i].id),
                        ),
                        onDismiss: (i, _) async {
                          await ref
                              .read(foldersProvider.notifier)
                              .remove(list[i].id);
                          return true;
                        },
                        style: M3EDismissibleCardStyle(
                          outerRadius: 32,
                          innerRadius: 14,
                          gap: 12,
                          color: colors.surfaceContainerHigh,
                          padding: const EdgeInsets.all(20),
                        ),
                        listPadding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path == null) return;

    final added = await ref.read(foldersProvider.notifier).add(path);
    if (!added && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.t.folders.alreadyAdded)));
    }
  }
}

class _FolderTile extends ConsumerWidget {
  const _FolderTile({required this.folder, required this.onRemove});

  final FolderConfig folder;
  final Future<void> Function() onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(folderFileCountProvider(folder.id));
    final colors = context.colors;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Row(
          children: [
            ExpressiveIconContainer(
              icon: Icons.folder_rounded,
              color: colors.primaryContainer,
              foregroundColor: colors.onPrimaryContainer,
              size: 48,
              radius: 18,
            ).padding(right: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(folder.label).size(16).weight(.w700),
                  Text(folder.localPath)
                      .size(12)
                      .color(colors.onSurfaceVariant)
                      .maxLines(1)
                      .overflow(.ellipsis),
                ],
              ),
            ),
            IconButton(
              tooltip: context.t.folders.remove,
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: colors.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                Icons.insert_drive_file_rounded,
                size: 16,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ExpressiveSwitcher(
                  child: Text(
                    count.when(
                      data: (n) => context.t.folders.fileCount(n: n),
                      loading: () => context.t.folders.scanning,
                      error: (_, _) => '-',
                    ),
                    key: ValueKey(count.toString()),
                  ).size(13).weight(.w600).color(colors.onSurfaceVariant),
                ),
              ),
              M3EButton(
                onPressed: () async {
                  final scanned = await ref
                      .read(foldersProvider.notifier)
                      .scan(folder);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.t.folders.scanned(count: scanned))),
                    );
                  }
                },
                style: .tonal,
                size: .sm,
                child: Row(
                  mainAxisSize: .min,
                  children: [
                    const Icon(Icons.sync_rounded, size: 16),
                    const SizedBox(width: 6),
                    Text(context.t.folders.scan),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
