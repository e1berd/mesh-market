import 'package:declar_ui/declar_ui.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_core/m3e_core.dart';

import '../../core/byte_size.dart';
import '../../core/models.dart';
import '../../core/pairing.dart';
import '../../i18n/strings.g.dart';
import '../../platform/open_path.dart';
import '../../platform/storage_access.dart';
import '../../state/conflicts_provider.dart';
import '../../state/folders_provider.dart';
import '../../state/peers_provider.dart';
import '../../state/share_controller.dart';
import '../widgets/conflict_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/expressive.dart';
import 'add_folder_screen.dart';

class FoldersScreen extends ConsumerWidget {
  const FoldersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Padding(
            padding: expressiveScreenPadding(context).copyWith(bottom: 8),
            child: ExpressiveReveal(
              child: Align(
                alignment:
                    MediaQuery.sizeOf(context).width >=
                        expressiveMediumBreakpoint
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: M3EButton.icon(
                  onPressed: () => _add(context, ref),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(context.t.folders.add),
                  size: .md,
                ),
              ),
            ),
          ),
          Expanded(
            child: ExpressiveSwitcher(child: _foldersBody(context, ref)),
          ),
        ],
      ),
    );
  }

  Widget _foldersBody(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(foldersProvider);
    final colors = context.colors;

    return folders.when(
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
      data: (list) {
        if (list.isEmpty) {
          return EmptyState(
            key: const ValueKey('folders-empty'),
            icon: Icons.create_new_folder_rounded,
            title: context.t.folders.empty,
            message: context.t.folders.emptyHint,
          );
        }

        if (MediaQuery.sizeOf(context).width >= expressiveMediumBreakpoint) {
          return SizedBox.expand(
            child: ExpressiveSwitcher(
              alignment: Alignment.topLeft,
              child: _DesktopFolderGrid(
                key: ValueKey(list.map((folder) => folder.id).join('|')),
                folders: list,
              ),
            ),
          );
        }

        return M3EDismissibleCardList(
          key: const ValueKey('folders-list'),
          itemCount: list.length,
          itemBuilder: (ctx, i) => _FolderTile(
            folder: list[i],
            showRemove: false,
            onRemove: () =>
                ref.read(foldersProvider.notifier).remove(list[i].id),
          ),
          onDismiss: (i, _) async {
            await ref.read(foldersProvider.notifier).remove(list[i].id);
            return true;
          },
          style: M3EDismissibleCardStyle(
            outerRadius: expressiveListOuterRadius,
            innerRadius: expressiveListInnerRadius,
            gap: expressiveListGap,
            color: colors.surfaceContainerHigh,
            padding: expressiveListPadding,
            margin: expressiveListMargin,
            backgroundBorderRadius: expressiveListOuterRadius,
            secondaryBackgroundBorderRadius: expressiveListOuterRadius,
            background: _deleteBackground(context, Alignment.centerLeft),
            secondaryBackground: _deleteBackground(
              context,
              Alignment.centerRight,
            ),
          ),
          listPadding: expressiveListPaddingFor(context),
        );
      },
    );
  }

  Widget _deleteBackground(BuildContext context, Alignment alignment) {
    final colors = context.colors;
    return Container(
      alignment: alignment,
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(32),
      ),
      child: OverflowBox(
        alignment: alignment,
        minWidth: 0,
        maxWidth: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            mainAxisSize: .min,
            children: [
              Icon(Icons.delete_rounded, color: colors.onErrorContainer),
              const SizedBox(width: 10),
              Text(
                context.t.folders.remove,
              ).size(14).weight(.w700).color(colors.onErrorContainer),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    if (!await ensureStorageAccess()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t.folders.storageDenied)),
        );
      }
      return;
    }
    final picked = await FilePicker.platform.getDirectoryPath();
    if (picked == null) return;
    final path = resolveAndroidDirectory(picked);

    if (context.mounted) context.push(AddFolderScreen(path: path));
  }
}

class _FolderTile extends ConsumerStatefulWidget {
  const _FolderTile({
    required this.folder,
    required this.onRemove,
    required this.showRemove,
  });

  final FolderConfig folder;
  final Future<void> Function() onRemove;
  final bool showRemove;

  @override
  ConsumerState<_FolderTile> createState() => _FolderTileState();
}

class _FolderTileState extends ConsumerState<_FolderTile> {
  bool _scanning = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scan());
  }

  Future<void> _scan() async {
    try {
      await ref.read(foldersProvider.notifier).scan(widget.folder);
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final folder = widget.folder;
    final size = ref.watch(folderSizeProvider(folder.id));
    final conflicts =
        ref.watch(folderConflictsProvider(folder.id)).value ?? const [];
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
                        ref
                                .watch(folderExistsProvider(folder.localPath))
                                .value ??
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
              tooltip: context.t.folders.openFolder,
              onPressed: () => _openFolder(context, folder),
              icon: const Icon(Icons.folder_open_rounded),
            ),
            IconButton(
              tooltip: context.t.folders.manageAccess,
              onPressed: () => _showAccess(context, ref, folder),
              icon: const Icon(Icons.group_rounded),
            ),
            if (widget.showRemove)
              IconButton(
                tooltip: context.t.folders.remove,
                onPressed: widget.onRemove,
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
                  child: (_scanning || size.isLoading)
                      ? Row(
                          key: const ValueKey('folder-scanning'),
                          mainAxisSize: .min,
                          children: [
                            const ExpressiveLoadingIndicator(
                              constraints: BoxConstraints.tightFor(
                                width: 18,
                                height: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(context.t.folders.scanning)
                                .size(13)
                                .weight(.w600)
                                .color(colors.onSurfaceVariant),
                          ],
                        )
                      : Text(
                          size.when(
                            data: (n) {
                              final formatted = n == 0
                                  ? context.t.folders.folderSize(n: 0, size: '')
                                  : context.t.folders.folderSize(
                                      n: 1,
                                      size: formatBytes(n, [
                                        'B',
                                        'KB',
                                        'MB',
                                        'GB',
                                        'TB',
                                      ]),
                                    );
                              return formatted;
                            },
                            loading: () => context.t.folders.scanning,
                            error: (_, _) => '-',
                          ),
                          key: ValueKey('folder-size-${size.value}'),
                        ).size(13).weight(.w600).color(colors.onSurfaceVariant),
                ),
              ),
              M3EButton(
                onPressed: () async {
                  await ref.read(foldersProvider.notifier).scan(folder);
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
        if (conflicts.isNotEmpty) ...[
          const SizedBox(height: 10),
          Material(
            color: colors.errorContainer,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => showConflictSheet(context, folder.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: colors.onErrorContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.t.folders.conflicts(n: conflicts.length),
                      ).size(14).weight(.w800).color(colors.onErrorContainer),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colors.onErrorContainer,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _openFolder(BuildContext context, FolderConfig folder) async {
    final opened = await openFolderInFileManager(folder.localPath);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.t.folders.openFailed)));
    }
  }
}

class _DesktopFolderGrid extends ConsumerWidget {
  const _DesktopFolderGrid({super.key, required this.folders});

  final List<FolderConfig> folders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = expressiveScreenPadding(context).copyWith(top: 0);
        const gap = 16.0;
        final available = _desktopGridAvailable(constraints.maxWidth, padding);
        final columns = _desktopGridColumns(available);
        final contentWidth = _desktopGridWidth(constraints.maxWidth, padding);
        final tileWidth = (contentWidth - gap * (columns - 1)) / columns;

        return SingleChildScrollView(
          key: const ValueKey('folders-grid'),
          padding: padding,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: contentWidth,
              child: Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final folder in folders)
                    SizedBox(
                      width: tileWidth,
                      child: ExpressivePanel(
                        padding: const EdgeInsets.all(20),
                        child: _FolderTile(
                          folder: folder,
                          showRemove: true,
                          onRemove: () async {
                            await ref
                                .read(foldersProvider.notifier)
                                .remove(folder.id);
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

double _desktopGridAvailable(double maxWidth, EdgeInsets padding) {
  final available = maxWidth - padding.horizontal;
  return available <= 0 ? 0 : available;
}

int _desktopGridColumns(double available) {
  const minTileWidth = 360.0;
  const gap = 16.0;
  final threeColumnsWidth = minTileWidth * 3 + gap * 2;
  return available >= threeColumnsWidth ? 3 : 2;
}

double _desktopGridWidth(double maxWidth, EdgeInsets padding) {
  const maxTileWidth = 420.0;
  const gap = 16.0;
  final available = _desktopGridAvailable(maxWidth, padding);
  if (available == 0) return 0;
  final columns = _desktopGridColumns(available);
  final preferred = columns * maxTileWidth + (columns - 1) * gap;
  return preferred <= available ? preferred : available;
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

    final peers =
        ref.watch(pairedPeersProvider).value ?? const <PairingPayload>[];
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
                  child: Text(
                    context.t.folders.localFolder,
                  ).size(15).weight(.w600),
                ),
                Text(
                  exists
                      ? context.t.folders.localAvailable
                      : context.t.folders.localMissing,
                ).size(13).color(colors.onSurfaceVariant),
              ],
            ),
            const Divider(height: 28),
            Text(
              context.t.folders.access,
            ).size(13).weight(.w800).letterSpacing(.5).color(colors.primary),
            const SizedBox(height: 4),
            if (peers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  context.t.folders.noPeers,
                ).size(14).color(colors.onSurfaceVariant).align(.center),
              )
            else
              for (final peer in peers)
                _PeerAccessTile(folder: current, peer: peer),
          ],
        ),
      ),
    );
  }
}

class _PeerAccessTile extends ConsumerWidget {
  const _PeerAccessTile({required this.folder, required this.peer});

  final FolderConfig folder;
  final PairingPayload peer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final hasAccess = folder.peerIds.contains(peer.deviceId);
    final peerConfig = folder.peer(peer.deviceId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              Row(
                children: [
                  _statusDot(context, hasAccess),
                  const SizedBox(width: 12),
                  Expanded(child: Text(peer.name).size(15).weight(.w600)),
                  Switch(
                    value: hasAccess,
                    onChanged: (granted) =>
                        _toggleAccess(ref, folder, peer, granted),
                  ),
                ],
              ),
              if (hasAccess && peerConfig != null) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    context.t.folders.sendFiles,
                  ).size(13).weight(.w500),
                  value: peerConfig.canSend,
                  onChanged: (value) => ref
                      .read(foldersProvider.notifier)
                      .updatePeer(folder.id, peer.deviceId, canSend: value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    context.t.folders.receiveFiles,
                  ).size(13).weight(.w500),
                  value: peerConfig.canReceive,
                  onChanged: (value) => ref
                      .read(foldersProvider.notifier)
                      .updatePeer(folder.id, peer.deviceId, canReceive: value),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _toggleAccess(
    WidgetRef ref,
    FolderConfig folder,
    PairingPayload peer,
    bool granted,
  ) {
    if (granted) {
      ref.read(shareControllerProvider).shareWith(folder, peer);
    } else {
      ref.read(foldersProvider.notifier).removePeer(folder.id, peer.deviceId);
    }
  }
}
