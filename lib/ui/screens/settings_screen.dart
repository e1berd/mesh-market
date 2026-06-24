import 'package:declar_ui/declar_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:motor/motor.dart';

import '../../i18n/strings.g.dart';
import '../../state/activity_log_provider.dart';
import '../../state/app_providers.dart';
import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

import '../../transport/hotspot.dart';
import '../theme.dart';
import '../widgets/expressive.dart';
import '../widgets/ice_server_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(configProvider);
    final notifier = ref.read(configProvider.notifier);
    final colors = context.colors;

    final sections = [
      ExpressiveSection(
        title: context.t.settings.appearance,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, c) {
                final w = _segmentWidth(c.maxWidth, 3);
                return M3EToggleButtonGroup(
                  actions: [
                    M3EToggleButtonGroupAction(
                      icon: const Icon(Icons.brightness_auto_rounded),
                      width: w,
                    ),
                    M3EToggleButtonGroupAction(
                      icon: const Icon(Icons.light_mode_rounded),
                      width: w,
                    ),
                    M3EToggleButtonGroupAction(
                      icon: const Icon(Icons.dark_mode_rounded),
                      width: w,
                    ),
                  ],
                  type: .connected,
                  size: .sm,
                  style: .tonal,
                  overflow: M3EButtonGroupOverflow.none,
                  selectedIndex: config.themeMode.index,
                  onSelectedIndexChanged: (i) {
                    if (i != null) notifier.setThemeMode(ThemeMode.values[i]);
                  },
                );
              },
            ),
          ),
          _PalettePicker(
            selectedId: config.themeSchemeId,
            onSelected: notifier.setThemeScheme,
          ),
        ],
      ),
      ExpressiveSection(
        title: context.t.settings.languageTitle,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: .stretch,
              children: [
                Text(
                  context.t.settings.languageSubtitle,
                ).size(14).color(colors.onSurface).padding(bottom: 12),
                LayoutBuilder(
                  builder: (context, c) {
                    final w = _segmentWidth(c.maxWidth, 2);
                    return M3EToggleButtonGroup(
                      actions: [
                        M3EToggleButtonGroupAction(
                          label: Text(context.t.settings.languageEnglish),
                          width: w,
                        ),
                        M3EToggleButtonGroupAction(
                          label: Text(context.t.settings.languageRussian),
                          width: w,
                        ),
                      ],
                      type: .connected,
                      size: .sm,
                      style: .tonal,
                      overflow: M3EButtonGroupOverflow.none,
                      selectedIndex:
                          LocaleSettings.currentLocale == AppLocale.en ? 0 : 1,
                      onSelectedIndexChanged: (i) {
                        if (i != null) {
                          notifier.setLocale(
                            i == 0 ? AppLocale.en : AppLocale.ru,
                          );
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      ExpressiveSection(
        title: context.t.settings.discovery,
        children: [
          _SettingTile(
            icon: Icons.wifi_rounded,
            title: context.t.settings.lanTitle,
            subtitle: context.t.settings.lanSubtitle,
            trailing: Switch(
              value: config.lanDiscovery,
              onChanged: notifier.toggleLanDiscovery,
            ),
          ),
          _SettingTile(
            icon: Icons.public_rounded,
            title: context.t.settings.dhtTitle,
            subtitle: context.t.settings.dhtSubtitle,
            trailing: Switch(
              value: config.dhtDiscovery,
              onChanged: notifier.toggleDhtDiscovery,
            ),
          ),
          _SettingTile(
            icon: Icons.router_rounded,
            title: context.t.settings.portMappingTitle,
            subtitle: context.t.settings.portMappingSubtitle,
            trailing: Switch(
              value: config.portMapping,
              onChanged: notifier.togglePortMapping,
            ),
          ),
          _SettingTile(
            icon: Icons.hub_rounded,
            title: context.t.settings.peerRelayTitle,
            subtitle: context.t.settings.peerRelaySubtitle,
            trailing: Switch(
              value: config.peerRelay,
              onChanged: notifier.togglePeerRelay,
            ),
          ),
          _SettingTile(
            icon: Icons.bolt_rounded,
            title: context.t.settings.holePunchTitle,
            subtitle: context.t.settings.holePunchSubtitle,
            trailing: Switch(
              value: config.holePunch,
              onChanged: notifier.toggleHolePunch,
            ),
          ),
          _SettingTile(
            icon: Icons.bluetooth_rounded,
            title: context.t.settings.bluetoothTitle,
            subtitle: context.t.settings.bluetoothSubtitle,
            trailing: Switch(
              value: config.bluetoothDiscovery,
              onChanged: notifier.toggleBluetoothDiscovery,
            ),
          ),
          if (Platform.isAndroid) ...[
            _SettingTile(
              icon: Icons.wifi_tethering_rounded,
              title: context.t.settings.wifiDirectTitle,
              subtitle: context.t.settings.wifiDirectSubtitle,
              trailing: Switch(
                value: config.wifiDirectDiscovery,
                onChanged: notifier.toggleWifiDirect,
              ),
            ),
            _SettingTile(
              icon: Icons.cell_tower_rounded,
              title: context.t.settings.wifiAwareTitle,
              subtitle: context.t.settings.wifiAwareSubtitle,
              trailing: Switch(
                value: config.wifiAwareDiscovery,
                onChanged: notifier.toggleWifiAware,
              ),
            ),
            _SettingTile(
              icon: Icons.router_rounded,
              title: context.t.settings.hotspotTitle,
              subtitle: context.t.settings.hotspotSubtitle,
              trailing: Switch(
                value: config.hotspotFallback,
                onChanged: notifier.toggleHotspot,
              ),
            ),
            if (config.hotspotFallback) const _HotspotCreateButton(),
          ],
          if (Platform.isIOS || Platform.isMacOS)
            _SettingTile(
              icon: Icons.devices_rounded,
              title: context.t.settings.multipeerTitle,
              subtitle: context.t.settings.multipeerSubtitle,
              trailing: Switch(
                value: config.multipeerDiscovery,
                onChanged: notifier.toggleMultipeer,
              ),
            ),
          if (Platform.isAndroid || Platform.isIOS)
            _SettingTile(
              icon: Icons.nfc_rounded,
              title: context.t.settings.nfcTitle,
              subtitle: context.t.settings.nfcSubtitle,
              trailing: Switch(
                value: config.nfcPairing,
                onChanged: notifier.toggleNfc,
              ),
            ),
          _SettingTile(
            icon: Icons.sync_rounded,
            title: context.t.settings.backgroundTitle,
            subtitle: context.t.settings.backgroundSubtitle,
            trailing: Switch(
              value: config.syncInBackground,
              onChanged: notifier.toggleBackground,
            ),
          ),
        ],
      ),
      const _LogSettingsSection(),
      ExpressiveSection(
        title: context.t.settings.signaling,
        trailing: M3EButton.icon(
          onPressed: () async {
            final server = await showIceServerDialog(context);
            if (server != null) notifier.addIceServer(server);
          },
          icon: const Icon(Icons.add_rounded),
          label: Text(context.t.settings.addServer),
          style: .tonal,
          size: .sm,
        ),
        children: [
          if (config.iceServers.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                context.t.settings.defaultStun,
              ).size(14).color(colors.onSurfaceVariant).align(.center),
            ),
          for (var i = 0; i < config.iceServers.length; i++)
            _SettingTile(
              icon: config.iceServers[i].isTurn
                  ? Icons.dns_rounded
                  : Icons.lan_rounded,
              title: config.iceServers[i].url,
              subtitle: config.iceServers[i].isTurn ? 'TURN' : 'STUN',
              trailing: IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => notifier.removeIceServer(i),
              ),
            ),
        ],
      ),
    ];

    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final padding = expressiveScreenPadding(context);

          return SingleChildScrollView(
            clipBehavior: Clip.hardEdge,
            child: ExpressiveResponsiveCenter(
              maxWidth: 860,
              padding: padding,
              child: Column(
                crossAxisAlignment: .stretch,
                spacing: 16,
                children: sections,
              ),
            ),
          );
        },
      ),
    );
  }
}

double _segmentWidth(double maxWidth, int count) {
  const connectedGap = 2.0;
  const focusRingSlack = 4.0;
  final usable = maxWidth - (count - 1) * connectedGap - focusRingSlack;
  return usable / count;
}

class _LogSettingsSection extends ConsumerWidget {
  const _LogSettingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final path = ref.watch(activityLogPathProvider);
    final controller = ref.read(activityLogControllerProvider);
    final t = context.t.settings;

    return ExpressiveSection(
      title: t.logsTitle,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t.logPath,
              ).size(12).weight(.w700).color(colors.onSurfaceVariant),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  path.value ?? '...',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ).size(12).color(colors.onSurface),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 430;
                  final actions = [
                    _LogAction(
                      icon: Icons.edit_rounded,
                      label: t.changeLogPath,
                      onPressed: () async {
                        final selected = await controller.choosePath(
                          dialogTitle: t.changeLogPath,
                        );
                        if (selected != null && context.mounted) {
                          context.showSnackBar(t.logPathChanged);
                        }
                      },
                    ),
                    _LogAction(
                      icon: Icons.folder_open_rounded,
                      label: t.openLogLocation,
                      onPressed: () async {
                        final opened = await controller.openLocation();
                        if (!opened && context.mounted) {
                          context.showSnackBar(t.logOpenFailed);
                        }
                      },
                    ),
                    _LogAction(
                      icon: Icons.delete_sweep_rounded,
                      label: t.clearLogs,
                      onPressed: () async {
                        await controller.clear();
                        if (context.mounted) {
                          context.showSnackBar(t.logsCleared);
                        }
                      },
                    ),
                  ];

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 8,
                      children: [
                        for (final action in actions)
                          _LogActionButton(action: action),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      for (var i = 0; i < actions.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(child: _LogActionButton(action: actions[i])),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LogAction {
  const _LogAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
}

class _LogActionButton extends StatelessWidget {
  const _LogActionButton({required this.action});

  final _LogAction action;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: action.onPressed,
      icon: Icon(action.icon),
      label: Text(action.label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 14),
      ),
    );
  }
}

class _PalettePicker extends StatelessWidget {
  const _PalettePicker({required this.selectedId, required this.onSelected});

  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: pointThemeSchemes.length,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 160,
          mainAxisExtent: 92,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (context, index) {
          final scheme = pointThemeSchemes[index];
          final selected = scheme.id == selectedId;
          final preview = pointColorScheme(
            Theme.of(context).brightness,
            scheme.id,
          );
          return _PaletteCard(
            scheme: scheme,
            preview: preview,
            selected: selected,
            onTap: () => onSelected(scheme.id),
          );
        },
      ),
    );
  }
}

class _PaletteCard extends StatefulWidget {
  const _PaletteCard({
    required this.scheme,
    required this.preview,
    required this.selected,
    required this.onTap,
  });

  final PointThemeScheme scheme;
  final ColorScheme preview;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_PaletteCard> createState() => _PaletteCardState();
}

class _PaletteCardState extends State<_PaletteCard>
    with TickerProviderStateMixin {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  late final SingleMotionController _scaleCtrl;
  late final SingleMotionController _radiusCtrl;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = SingleMotionController(
      motion: M3EMotion.expressiveSpatialFast.toMotion(),
      vsync: this,
      initialValue: _scaleTarget,
    );
    _radiusCtrl = SingleMotionController(
      motion: M3EMotion.expressiveSpatialDefault.toMotion(),
      vsync: this,
      initialValue: _radiusTarget,
    );
  }

  double get _scaleTarget => _pressed
      ? .96
      : _isActive || widget.selected
      ? 1
      : .98;
  double get _radiusTarget => _pressed
      ? 18
      : _isActive || widget.selected
      ? 28
      : 22;
  bool get _isActive => _hovered || _focused || _pressed;

  @override
  void didUpdateWidget(_PaletteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      _scaleCtrl.animateTo(_scaleTarget);
      _radiusCtrl.animateTo(_radiusTarget);
    }
  }

  void _updateState() {
    setState(() {});
    _scaleCtrl.animateTo(_scaleTarget);
    _radiusCtrl.animateTo(_radiusTarget);
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _radiusCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final preview = widget.preview;
    final selected = widget.selected;
    final foreground = selected
        ? preview.onSecondaryContainer
        : colors.onSurface;
    final borderColor = selected || _focused
        ? preview.primary
        : _hovered
        ? preview.secondary
        : colors.outlineVariant;
    final stateLayerColor = _pressed
        ? preview.primary.withValues(alpha: .14)
        : _focused
        ? preview.primary.withValues(alpha: .12)
        : _hovered
        ? preview.primary.withValues(alpha: .08)
        : Colors.transparent;

    return Semantics(
      selected: selected,
      button: true,
      label: widget.scheme.name,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleCtrl, _radiusCtrl]),
        builder: (context, _) {
          final scale = _scaleCtrl.value;
          final radius = _radiusCtrl.value;
          final borderW = selected || _focused ? 2.0 : 1.0;

          return Transform.scale(
            scale: scale,
            child: AnimatedContainer(
              duration: expressiveFastDuration,
              curve: expressiveCurve,
              decoration: BoxDecoration(
                color: selected
                    ? preview.secondaryContainer
                    : _isActive
                    ? colors.surfaceContainerHigh
                    : colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: borderColor, width: borderW),
                boxShadow: [
                  if (_hovered && !_pressed)
                    BoxShadow(
                      color: preview.primary.withValues(alpha: .10),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  onHover: (v) {
                    _hovered = v;
                    _updateState();
                  },
                  onFocusChange: (v) {
                    _focused = v;
                    _updateState();
                  },
                  onTapDown: (_) {
                    _pressed = true;
                    _updateState();
                  },
                  onTapUp: (_) {
                    _pressed = false;
                    _updateState();
                  },
                  onTapCancel: () {
                    _pressed = false;
                    _updateState();
                  },
                  customBorder: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radius),
                  ),
                  overlayColor: const WidgetStatePropertyAll(
                    Colors.transparent,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AnimatedContainer(
                        duration: expressiveFastDuration,
                        curve: expressiveCurve,
                        color: stateLayerColor,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final compact = constraints.maxWidth < 92;
                                return Row(
                                  children: [
                                    _Swatch(
                                      color: preview.primary,
                                      compact: compact,
                                    ),
                                    _Swatch(
                                      color: preview.secondary,
                                      compact: compact,
                                    ),
                                    _Swatch(
                                      color: preview.tertiary,
                                      compact: compact,
                                    ),
                                    const Spacer(),
                                    AnimatedSwitcher(
                                      duration: expressiveFastDuration,
                                      child: selected
                                          ? Icon(
                                              Icons.check_circle_rounded,
                                              key: const ValueKey('selected'),
                                              size: compact ? 18 : 20,
                                              color:
                                                  preview.onSecondaryContainer,
                                            )
                                          : Icon(
                                              widget.scheme.icon,
                                              key: const ValueKey('icon'),
                                              size: compact ? 18 : 20,
                                              color: _isActive
                                                  ? preview.primary
                                                  : colors.onSurfaceVariant,
                                            ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const Spacer(),
                            Text(
                              widget.scheme.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ).size(13).weight(.w800).color(foreground),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.compact});

  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 16.0 : 20.0;
    return Container(
      width: size,
      height: size,
      margin: EdgeInsets.only(right: compact ? 3 : 4),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: .8),
          width: 2,
        ),
      ),
    );
  }
}

class _HotspotCreateButton extends StatelessWidget {
  const _HotspotCreateButton();

  @override
  Widget build(BuildContext context) {
    final t = context.t.settings;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: M3EButton.icon(
          onPressed: () => _create(context),
          icon: const Icon(Icons.add_rounded),
          label: Text(t.hotspotCreate),
          style: .tonal,
          size: .sm,
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context) async {
    final t = context.t.settings;
    await [Permission.nearbyWifiDevices, Permission.location].request();
    try {
      final credentials = await const HotspotController().start();
      if (!context.mounted || credentials == null) return;
      context.showSnackBar(
        '${t.hotspotActive(ssid: credentials.ssid)}\n'
        '${t.hotspotPassword(password: credentials.passphrase)}',
      );
    } on Object {
      if (context.mounted) context.showSnackBar(t.hotspotFailed);
    }
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListTile(
      leading: ExpressiveIconContainer(
        icon: icon,
        color: colors.secondaryContainer,
        foregroundColor: colors.onSecondaryContainer,
        size: 44,
        radius: 16,
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: AnimatedSwitcher(
        duration: expressiveFastDuration,
        child: trailing,
      ),
    );
  }
}
