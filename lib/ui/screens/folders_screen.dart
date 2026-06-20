import 'package:declar_ui/declar_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_core/m3e_core.dart';

import '../../core/models.dart';
import '../../state/folders_provider.dart';
import '../widgets/empty_state.dart';

class FoldersScreen extends ConsumerWidget {
  const FoldersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(foldersProvider);
    final colors = context.colors;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        M3EButton.icon(
          onPressed: () => _add(ref),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add folder'),
        ).padding(horizontal: 16, top: 12, bottom: 4),
        folders.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Could not load folders',
            message: '$error',
          ),
          data: (list) => list.isEmpty
              ? const Expanded(
                  child: EmptyState(
                    icon: Icons.create_new_folder_rounded,
                    title: 'No shared folders',
                    message: 'Add a folder to start syncing across your devices.',
                  ),
                )
              : Expanded(
                  child: M3EDismissibleCardList(
                    itemCount: list.length,
                    itemBuilder: (ctx, i) =>
                        _FolderTile(folder: list[i]),
                    onDismiss: (i, _) async {
                      await ref
                          .read(foldersProvider.notifier)
                          .remove(list[i].id);
                      return true;
                    },
                    style: M3EDismissibleCardStyle(
                      outerRadius: 28,
                      innerRadius: 14,
                      gap: 12,
                      color: colors.surfaceContainerHigh,
                      padding: const EdgeInsets.all(20),
                    ),
                    listPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _add(WidgetRef ref) async {
    final path = await FilePicker.getDirectoryPath();
    if (path != null) await ref.read(foldersProvider.notifier).add(path);
  }
}

class _FolderTile extends ConsumerWidget {
  const _FolderTile({required this.folder});

  final FolderConfig folder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(folderFileCountProvider(folder.id));
    final colors = context.colors;

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.folder_rounded,
                  color: colors.onPrimaryContainer),
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
              Icon(Icons.insert_drive_file_rounded,
                  size: 16, color: colors.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(count.when(
                  data: (n) => '$n files',
                  loading: () => 'Scanning…',
                  error: (_, _) => '—',
                ))
                    .size(13)
                    .weight(.w500)
                    .color(colors.onSurfaceVariant),
              ),
              M3EButton(
                onPressed: () async {
                  final scanned =
                      await ref.read(foldersProvider.notifier).scan(folder);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Scanned $scanned files')),
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
                    const Text('Scan'),
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
