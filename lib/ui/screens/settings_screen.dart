import 'package:declar_ui/declar_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:motor/motor.dart';

import '../../i18n/strings.g.dart';
import '../../state/app_providers.dart';
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

    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            clipBehavior: Clip.hardEdge,
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
            child: SizedBox(
              width: constraints.maxWidth,
              child: Column(
                crossAxisAlignment: .stretch,
                children: [
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
                                  icon: const Icon(
                                    Icons.brightness_auto_rounded,
                                  ),
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
                                if (i != null) {
                                  notifier.setThemeMode(ThemeMode.values[i]);
                                }
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
                            Text(context.t.settings.languageSubtitle)
                                .size(14)
                                .color(colors.onSurface)
                                .padding(bottom: 12),
                            LayoutBuilder(
                              builder: (context, c) {
                                final w = _segmentWidth(c.maxWidth, 2);
                                return M3EToggleButtonGroup(
                                  actions: [
                                    M3EToggleButtonGroupAction(
                                      label: Text(
                                        context.t.settings.languageEnglish,
                                      ),
                                      width: w,
                                    ),
                                    M3EToggleButtonGroupAction(
                                      label: Text(
                                        context.t.settings.languageRussian,
                                      ),
                                      width: w,
                                    ),
                                  ],
                                  type: .connected,
                                  size: .sm,
                                  style: .tonal,
                                  overflow: M3EButtonGroupOverflow.none,
                                  selectedIndex:
                                      LocaleSettings.currentLocale ==
                                          AppLocale.en
                                      ? 0
                                      : 1,
                                  onSelectedIndexChanged: (i) {
                                    if (i != null) {
                                      LocaleSettings.setLocale(
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
                        icon: Icons.bluetooth_rounded,
                        title: context.t.settings.bluetoothTitle,
                        subtitle: context.t.settings.bluetoothSubtitle,
                        trailing: Switch(
                          value: config.bluetoothDiscovery,
                          onChanged: notifier.toggleBluetoothDiscovery,
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
                  ExpressiveSection(
                    title: context.t.settings.signaling,
                    children: [
                      if (config.iceServers.isEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Text(context.t.settings.defaultStun)
                              .size(14)
                              .color(colors.onSurfaceVariant)
                              .align(.center),
                        ),
                      for (var i = 0; i < config.iceServers.length; i++)
                        _SettingTile(
                          icon: config.iceServers[i].isTurn
                              ? Icons.dns_rounded
                              : Icons.lan_rounded,
                          title: config.iceServers[i].url,
                          subtitle: config.iceServers[i].isTurn
                              ? 'TURN'
                              : 'STUN',
                          trailing: IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () => notifier.removeIceServer(i),
                          ),
                        ),
                    ],
                  ),
                  ExpressiveReveal(
                    child: M3EButton.icon(
                      onPressed: () async {
                        final server = await showIceServerDialog(context);
                        if (server != null) notifier.addIceServer(server);
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: Text(context.t.settings.addServer),
                      style: .tonal,
                      size: .md,
                    ).padding(horizontal: 16, top: 4),
                  ),
                ],
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
                            Row(
                              children: [
                                _Swatch(color: preview.primary),
                                _Swatch(color: preview.secondary),
                                _Swatch(color: preview.tertiary),
                                const Spacer(),
                                AnimatedSwitcher(
                                  duration: expressiveFastDuration,
                                  child: selected
                                      ? Icon(
                                          Icons.check_circle_rounded,
                                          key: const ValueKey('selected'),
                                          size: 20,
                                          color: preview.onSecondaryContainer,
                                        )
                                      : Icon(
                                          widget.scheme.icon,
                                          key: const ValueKey('icon'),
                                          size: 20,
                                          color: _isActive
                                              ? preview.primary
                                              : colors.onSurfaceVariant,
                                        ),
                                ),
                              ],
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
  const _Swatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.only(right: 4),
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
