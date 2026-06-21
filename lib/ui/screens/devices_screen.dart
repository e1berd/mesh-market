import 'package:declar_ui/declar_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_core/m3e_core.dart';

import '../../core/models.dart';
import '../../core/pairing.dart';
import '../../i18n/strings.g.dart';
import '../../state/folders_provider.dart';
import '../../state/identity_provider.dart';
import '../../state/peers_provider.dart';
import '../widgets/delete_swipe.dart';
import '../widgets/empty_state.dart';
import '../widgets/expressive.dart';

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(identityProvider);
    final name = ref.watch(deviceNameProvider);
    final peers = ref.watch(pairedPeersProvider);
    final colors = context.colors;

    return SafeArea(
      top: false,
      child: ExpressiveSwitcher(
        child: identity.when(
          loading: () => const Center(
            key: ValueKey('identity-loading'),
            child: CircularProgressIndicator(),
          ),
          error: (error, _) => EmptyState(
            key: const ValueKey('identity-error'),
            icon: Icons.error_outline_rounded,
            title: context.t.devices.errorLoad,
            message: '$error',
          ),
          data: (device) {
            if (MediaQuery.sizeOf(context).width >=
                expressiveMediumBreakpoint) {
              return SizedBox.expand(
                child: _DesktopDevicesLayout(name: name, peers: peers),
              );
            }

            return Column(
              key: const ValueKey('identity-data'),
              crossAxisAlignment: .stretch,
              children: [
                ExpressiveResponsiveCenter(
                  maxWidth: 1180,
                  padding: EdgeInsets.only(
                    top: expressiveScreenPadding(context).top,
                  ),
                  child: ExpressiveReveal(
                    child: M3ECardList(
                      itemCount: 1,
                      itemBuilder: (ctx, i) => _thisDevice(context, name),
                      outerRadius: expressiveListOuterRadius,
                      innerRadius: expressiveListInnerRadius,
                      gap: expressiveListGap,
                      color: colors.surfaceContainerHigh,
                      padding: expressiveListPadding,
                      margin: expressiveListMargin,
                    ),
                  ),
                ),
                ExpressiveResponsiveCenter(
                  maxWidth: 1180,
                  padding: EdgeInsets.fromLTRB(
                    expressiveScreenPadding(context).left,
                    24,
                    expressiveScreenPadding(context).right,
                    8,
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(context.t.devices.title)
                      .size(12)
                      .weight(.w800)
                      .letterSpacing(0)
                      .color(colors.primary),
                ),
                Expanded(child: _peersBody(context, ref, peers)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _peersBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<PairingPayload>> peers,
  ) {
    final colors = context.colors;
    return ExpressiveSwitcher(
      child: peers.when(
        loading: () => const Center(
          key: ValueKey('peers-loading'),
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => EmptyState(
          key: const ValueKey('peers-error'),
          icon: Icons.error_outline_rounded,
          title: context.t.devices.errorLoadPeers,
          message: '$error',
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              key: const ValueKey('peers-empty'),
              icon: Icons.devices_other_rounded,
              title: context.t.devices.empty,
              message: context.t.devices.emptyHint,
            );
          }

          return M3EDismissibleCardList(
            key: const ValueKey('peers-list'),
            itemCount: items.length,
            itemBuilder: (ctx, i) => _pairedDevice(context, ref, items[i]),
            onDismiss: (i, _) async {
              await ref
                  .read(pairedPeersProvider.notifier)
                  .remove(items[i].deviceId);
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
              background: deleteSwipeBackground(
                context,
                Alignment.centerLeft,
                context.t.devices.remove,
              ),
              secondaryBackground: deleteSwipeBackground(
                context,
                Alignment.centerRight,
                context.t.devices.remove,
              ),
            ),
            listPadding: expressiveListPaddingFor(context),
          );
        },
      ),
    );
  }

  Widget _thisDevice(BuildContext context, AsyncValue<String> name) {
    final colors = context.colors;
    final currentName = name.hasValue ? name.value : null;
    return Row(
      children: [
        ExpressiveIconContainer(
          icon: Icons.computer_rounded,
          color: colors.primaryContainer,
          foregroundColor: colors.onPrimaryContainer,
        ).padding(right: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              AnimatedSwitcher(
                duration: expressiveFastDuration,
                child: name.when(
                  data: (value) => Text(
                    value,
                    key: ValueKey(value),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ).size(16).weight(.w700),
                  loading: () => Text(
                    'Loading name',
                    key: const ValueKey('device-name-loading'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ).size(16).weight(.w700),
                  error: (_, _) => Text(
                    defaultDeviceName(),
                    key: const ValueKey('device-name-error'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ).size(16).weight(.w700),
                ),
              ),
              Text(
                context.t.devices.thisDevice,
              ).size(12).color(colors.onSurfaceVariant),
            ],
          ),
        ),
        Row(
          mainAxisSize: .min,
          children: [
            IconButton(
              tooltip: 'Rename device',
              onPressed: currentName == null
                  ? null
                  : () => _showRenameDialog(context, currentName),
              icon: const Icon(Icons.edit_rounded),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    String currentName,
  ) async {
    final renamed = await showDialog<bool>(
      context: context,
      builder: (_) => _RenameDeviceDialog(initialName: currentName),
    );

    if (renamed == true && context.mounted) {
      context.showSnackBar('Device name updated');
    }
  }

  Widget _pairedDevice(
    BuildContext context,
    WidgetRef ref,
    PairingPayload peer,
  ) {
    return _PairedDeviceContent(peer: peer, showRemove: false);
  }
}

class _DesktopDevicesLayout extends ConsumerWidget {
  const _DesktopDevicesLayout({required this.name, required this.peers});

  final AsyncValue<String> name;
  final AsyncValue<List<PairingPayload>> peers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final padding = expressiveScreenPadding(context);
    final colors = context.colors;

    return SingleChildScrollView(
      key: const ValueKey('devices-desktop'),
      padding: padding,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ExpressiveReveal(
                  child: M3ECardList(
                    itemCount: 1,
                    itemBuilder: (ctx, i) =>
                        const DevicesScreen()._thisDevice(context, name),
                    outerRadius: expressiveListOuterRadius,
                    innerRadius: expressiveListInnerRadius,
                    gap: expressiveListGap,
                    color: colors.surfaceContainerHigh,
                    padding: expressiveListPadding,
                    margin: expressiveListMargin,
                  ),
                ),
                Text(context.t.devices.title)
                    .size(12)
                    .weight(.w800)
                    .letterSpacing(0)
                    .color(colors.primary)
                    .padding(left: 20, top: 26, bottom: 8),
                peers.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.only(top: 96),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => EmptyState(
                    key: const ValueKey('peers-error-desktop'),
                    icon: Icons.error_outline_rounded,
                    title: context.t.devices.errorLoadPeers,
                    message: '$error',
                  ),
                  data: (items) => items.isEmpty
                      ? EmptyState(
                          key: const ValueKey('peers-empty-desktop'),
                          icon: Icons.devices_other_rounded,
                          title: context.t.devices.empty,
                          message: context.t.devices.emptyHint,
                        )
                      : AnimatedSwitcher(
                          duration: expressiveDuration,
                          reverseDuration: expressiveFastDuration,
                          switchInCurve: expressiveCurve,
                          switchOutCurve: expressiveExitCurve,
                          child: _DesktopPeerList(
                            key: ValueKey(
                              items.map((peer) => peer.deviceId).join('|'),
                            ),
                            items: items,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopPeerList extends StatelessWidget {
  const _DesktopPeerList({super.key, required this.items});

  final List<PairingPayload> items;

  @override
  Widget build(BuildContext context) {
    return M3ECardList(
      itemCount: items.length,
      itemBuilder: (context, index) =>
          _PairedDeviceContent(peer: items[index], showRemove: true),
      outerRadius: expressiveListOuterRadius,
      innerRadius: expressiveListInnerRadius,
      gap: expressiveListGap,
      color: context.colors.surfaceContainerHigh,
      padding: expressiveListPadding,
      margin: expressiveListMargin,
    );
  }
}

class _PairedDeviceContent extends ConsumerWidget {
  const _PairedDeviceContent({required this.peer, required this.showRemove});

  final PairingPayload peer;
  final bool showRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final folders = ref.watch(foldersProvider).value ?? const <FolderConfig>[];
    final sharedFolders = [
      for (final folder in folders)
        if (folder.peerIds.contains(peer.deviceId)) folder,
    ];

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Row(
          children: [
            ExpressiveIconContainer(
              icon: Icons.devices_other_rounded,
              color: colors.secondaryContainer,
              foregroundColor: colors.onSecondaryContainer,
            ).padding(right: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(peer.name).size(16).weight(.w700),
                  Text(
                    peer.deviceId,
                  ).size(12).color(colors.onSurfaceVariant).overflow(.ellipsis),
                ],
              ),
            ),
            if (showRemove)
              IconButton(
                tooltip: context.t.devices.remove,
                onPressed: () => ref
                    .read(pairedPeersProvider.notifier)
                    .remove(peer.deviceId),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
          ],
        ),
        if (sharedFolders.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final folder in sharedFolders)
            _FolderStatusChip(folder: folder, peer: peer),
        ],
      ],
    );
  }
}

class _FolderStatusChip extends ConsumerWidget {
  const _FolderStatusChip({required this.folder, required this.peer});

  final FolderConfig folder;
  final PairingPayload peer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final peerConfig = folder.peer(peer.deviceId);
    final canSend = peerConfig?.canSend ?? true;
    final canReceive = peerConfig?.canReceive ?? true;
    final hasError = !canSend && !canReceive;
    final dotColor = hasError ? colors.error : colors.primary;

    final parts = <String>[];
    if (canSend) parts.add(context.t.folders.sendFiles);
    if (canReceive) parts.add(context.t.folders.receiveFiles);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(Icons.folder_rounded, size: 16, color: dotColor),
          const SizedBox(width: 8),
          Expanded(child: Text(folder.label).size(13).weight(.w500)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: hasError
                  ? colors.errorContainer
                  : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                Text(
                      hasError
                          ? context.t.folders.remoteMissing
                          : parts.join(' · '),
                    )
                    .size(11)
                    .weight(.w600)
                    .color(
                      hasError
                          ? colors.onErrorContainer
                          : colors.onSurfaceVariant,
                    ),
          ),
        ],
      ),
    );
  }
}

class _RenameDeviceDialog extends ConsumerStatefulWidget {
  const _RenameDeviceDialog({required this.initialName});

  final String initialName;

  @override
  ConsumerState<_RenameDeviceDialog> createState() =>
      _RenameDeviceDialogState();
}

class _RenameDeviceDialogState extends ConsumerState<_RenameDeviceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename this device'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          maxLength: 48,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Device name',
            hintText: 'My phone',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Enter a device name';
            }
            return null;
          },
          onFieldSubmitted: (_) => _save(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    try {
      await ref.read(deviceNameProvider.notifier).rename(_controller.text);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      context.showSnackBar('$error');
    }
  }
}
