import 'package:declar_ui/declar_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_core/m3e_core.dart';

import '../../core/pairing.dart';
import '../../i18n/strings.g.dart';
import '../../state/identity_provider.dart';
import '../../state/peers_provider.dart';
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
          data: (device) => Column(
            key: const ValueKey('identity-data'),
            crossAxisAlignment: .stretch,
            children: [
              ExpressiveReveal(
                child: M3ECardList(
                  itemCount: 1,
                  itemBuilder: (ctx, i) => _thisDevice(context, name),
                  outerRadius: 32,
                  innerRadius: 12,
                  gap: 0,
                  color: colors.surfaceContainerHigh,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Text(
                  context.t.devices.title,
                ).size(12).weight(.w800).letterSpacing(0).color(colors.primary),
              ),
              Expanded(
                child: ExpressiveSwitcher(
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

                      return M3ECardList.builder(
                        key: const ValueKey('peers-list'),
                        itemCount: items.length,
                        itemBuilder: (ctx, i) =>
                            _pairedDevice(context, ref, items[i]),
                        outerRadius: 32,
                        innerRadius: 12,
                        gap: 8,
                        color: colors.surfaceContainerHigh,
                        padding: const EdgeInsets.all(16),
                        listPadding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
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
              Text(context.t.devices.thisDevice).size(12).color(colors.onSurfaceVariant),
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
        ExpressiveStatusPill(
          icon: Icons.bolt_rounded,
          label: context.t.devices.online,
          color: colors.tertiaryContainer,
          foregroundColor: colors.onTertiaryContainer,
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
    final colors = context.colors;

    return Row(
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
        IconButton(
          tooltip: context.t.devices.remove,
          onPressed: () =>
              ref.read(pairedPeersProvider.notifier).remove(peer.deviceId),
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ],
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
