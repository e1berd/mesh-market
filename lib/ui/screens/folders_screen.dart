import 'package:declar_ui/declar_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_core/m3e_core.dart';

import '../../core/models.dart';
import '../../core/pairing.dart';
import '../../i18n/strings.g.dart';
import '../../state/folders_provider.dart';
import '../../state/peers_provider.dart';
import '../../state/share_controller.dart';
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
                          backgroundBorderRadius: 32,
                          secondaryBackgroundBorderRadius: 32,
                          background:
                              _deleteBackground(context, Alignment.centerLeft),
                          secondaryBackground:
                              _deleteBackground(context, Alignment.centerRight),
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

  Widget _deleteBackground(BuildContext context, Alignment alignment) {
    final colors = context.colors;
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        mainAxisSize: .min,
        children: [
          Icon(Icons.delete_rounded, color: colors.onErrorContainer),
          const SizedBox(width: 10),
          Text(context.t.folders.remove)
              .size(14)
              .weight(.w700)
              .color(colors.onErrorContainer),
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

class _FolderTile extends ConsumerStatefulWidget {
  const _FolderTile({required this.folder, required this.onRemove});

  final FolderConfig folder;
  final Future<void> Function() onRemove;

  @override
  ConsumerState<_FolderTile> createState() => _FolderTileState();
}

class _FolderTileState extends ConsumerState<_FolderTile> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(foldersProvider.notifier).scan(widget.folder);
    });
  }

  @override
  Widget build(BuildContext context) {
    final folder = widget.folder;
    final onRemove = widget.onRemove;
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
                  Row(
                    children: [
                      _statusDot(
                        context,
                        ref.watch(folderExistsProvider(folder.localPath)).value ??
                            false,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(folder.label)
                            .size(16)
                            .weight(.w700)
                            .maxLines(1)
                            .overflow(.ellipsis),
                      ),
                    ],
                  ),
                  Text(folder.localPath)
                      .size(12)
                      .color(colors.onSurfaceVariant)
                      .maxLines(1)
                      .overflow(.ellipsis),
                ],
              ),
            ),
            IconButton(
              tooltip: context.t.folders.manageAccess,
              onPressed: () => _showAccess(context, ref, folder),
              icon: const Icon(Icons.group_rounded),
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

Widget _statusDot(BuildContext context, bool ok) => Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ok ? const Color(0xFF34A853) : context.colors.error,
      ),
    );

void _showAccess(BuildContext context, WidgetRef ref, FolderConfig folder) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _FolderAccessSheet(folderId: folder.id),
  );
}

class _FolderAccessSheet extends ConsumerWidget {
  const _FolderAccessSheet({required this.folderId});

  final String folderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final folders = ref.watch(foldersProvider).value ?? const <FolderConfig>[];
    FolderConfig? match;
    for (final folder in folders) {
      if (folder.id == folderId) {
        match = folder;
        break;
      }
    }
    if (match == null) return const SizedBox.shrink();
    final current = match;

    final peers = ref.watch(pairedPeersProvider).value ?? const <PairingPayload>[];
    final exists =
        ref.watch(folderExistsProvider(current.localPath)).value ?? false;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            Text(current.label).size(20).weight(.w800).align(.center),
            const SizedBox(height: 18),
            Row(
              children: [
                _statusDot(context, exists),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(context.t.folders.localFolder).size(15).weight(.w600),
                ),
                Text(exists
                        ? context.t.folders.localAvailable
                        : context.t.folders.localMissing)
                    .size(13)
                    .color(colors.onSurfaceVariant),
              ],
            ),
            const Divider(height: 28),
            Text(context.t.folders.access)
                .size(13)
                .weight(.w800)
                .letterSpacing(.5)
                .color(colors.primary),
            const SizedBox(height: 4),
            if (peers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(context.t.folders.noPeers)
                    .size(14)
                    .color(colors.onSurfaceVariant)
                    .align(.center),
              )
            else
              for (final peer in peers)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary:
                      _statusDot(context, current.peerIds.contains(peer.deviceId)),
                  title: Text(peer.name),
                  value: current.peerIds.contains(peer.deviceId),
                  onChanged: (granted) =>
                      _toggleAccess(ref, current, peer, granted),
                ),
          ],
        ),
      ),
    );
  }

  void _toggleAccess(
      WidgetRef ref, FolderConfig folder, PairingPayload peer, bool granted) {
    final notifier = ref.read(foldersProvider.notifier);
    if (granted) {
      notifier.addPeer(folder.id, peer.deviceId);
      ref.read(shareControllerProvider).shareWith(folder, peer);
    } else {
      notifier.removePeer(folder.id, peer.deviceId);
    }
  }
}
