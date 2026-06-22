import 'package:declar_ui/declar_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:motor/motor.dart';

import '../core/pairing.dart';
import '../i18n/strings.g.dart';
import '../platform/storage_access.dart';
import '../state/app_providers.dart';
import '../state/folders_provider.dart';
import '../state/incoming_pair_provider.dart';
import '../state/incoming_share_provider.dart';
import '../state/peers_provider.dart';
import '../state/sync_provider.dart';
import 'screens/activity_screen.dart';
import 'screens/devices_screen.dart';
import 'screens/folders_screen.dart';
import 'screens/pair_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/expressive.dart';

const _railWidth = 104.0;
const _railDestinationHeight = 78.0;
const _railIndicatorWidth = 64.0;
const _railIndicatorHeight = 40.0;
const _railLabelWidth = 76.0;

class _Destination {
  const _Destination(
    this.icon,
    this.selectedIcon,
    this.titleLabel,
    this.navLabel,
    this.screen,
  );

  final IconData icon;
  final IconData selectedIcon;
  final String titleLabel;
  final String navLabel;
  final Widget screen;
}

List<_Destination> _destinations(Translations t) => [
  _Destination(
    Icons.devices_outlined,
    Icons.devices_rounded,
    t.nav.devices,
    t.navShort.devices,
    DevicesScreen(),
  ),
  _Destination(
    Icons.folder_outlined,
    Icons.folder_rounded,
    t.nav.folders,
    t.navShort.folders,
    FoldersScreen(),
  ),
  _Destination(
    Icons.qr_code_scanner_outlined,
    Icons.qr_code_scanner_rounded,
    t.nav.pair,
    t.navShort.pair,
    PairScreen(),
  ),
  _Destination(
    Icons.sync_outlined,
    Icons.sync_rounded,
    t.nav.activity,
    t.navShort.activity,
    ActivityScreen(),
  ),
  _Destination(
    Icons.settings_outlined,
    Icons.settings_rounded,
    t.nav.settings,
    t.navShort.settings,
    SettingsScreen(),
  ),
];

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;
  final _handledShares = <IncomingShare>{};
  final _handledPairs = <IncomingPair>{};

  void _select(int next) => setState(() => _index = next);

  Future<void> _confirmPair(IncomingPair pending) async {
    final t = context.t;
    final colors = context.colors;
    final accept = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.pair.incomingTitle),
        content: Column(
          mainAxisSize: .min,
          children: [
            Text(t.pair.incomingBody(name: pending.payload.name)),
            const SizedBox(height: 18),
            Text(
              t.pair.verificationCode,
            ).size(12).weight(.w700).color(colors.onSurfaceVariant),
            Text(
              pending.code,
            ).size(34).weight(.w800).color(colors.primary).letterSpacing(4),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(t.pair.reject),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(t.pair.accept),
          ),
        ],
      ),
    );
    ref.read(incomingPairProvider.notifier).resolve(pending, accept ?? false);
    _handledPairs.remove(pending);
  }

  Future<void> _confirmShare(IncomingShare pending) async {
    final t = context.t;
    final peers =
        ref.read(pairedPeersProvider).value ?? const <PairingPayload>[];
    var name = pending.fromDeviceId;
    for (final peer in peers) {
      if (peer.deviceId == pending.fromDeviceId) {
        name = peer.name;
        break;
      }
    }

    final accept = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.share.incomingTitle),
        content: Text(
          t.share.incomingBody(name: name, folder: pending.share.label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(t.share.reject),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(t.share.accept),
          ),
        ],
      ),
    );

    final picked = accept == true && await ensureStorageAccess()
        ? await FilePicker.platform.getDirectoryPath()
        : null;
    final path = picked == null ? null : resolveAndroidDirectory(picked);
    final granted = path != null;
    if (granted) {
      await ref
          .read(foldersProvider.notifier)
          .acceptShare(pending.share, path, pending.fromDeviceId);
      ref.read(configProvider.notifier).setSyncNow(true);
    }
    ref.read(incomingShareProvider.notifier).resolve(pending, granted);
    _handledShares.remove(pending);
    if (granted && mounted) {
      context.showSnackBar(t.share.accepted(folder: pending.share.label));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(syncBindingProvider);

    ref.listen<List<IncomingShare>>(incomingShareProvider, (_, next) {
      for (final pending in next) {
        if (_handledShares.add(pending)) _confirmShare(pending);
      }
    });

    ref.listen<List<IncomingPair>>(incomingPairProvider, (_, next) {
      for (final pending in next) {
        if (_handledPairs.add(pending)) _confirmPair(pending);
      }
    });

    final destinations = _destinations(context.t);
    final active = destinations[_index];
    final colors = context.colors;
    final activeScreen = KeyedSubtree(
      key: ValueKey(active.titleLabel),
      child: active.screen,
    );

    if (context.width >= 720) {
      return Scaffold().body(
        Row(
          children: [
            _ExpressiveSideRail(
              selectedIndex: _index,
              onDestinationSelected: _select,
              destinations: destinations,
            ),
            VerticalDivider(width: 1, color: colors.outlineVariant),
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ExpressiveSwitcher(
                        child: Text(
                          active.titleLabel,
                          key: ValueKey(active.titleLabel),
                        ).size(28).weight(.w800).letterSpacing(0),
                      ),
                    ),
                  ),
                  Expanded(child: ExpressivePageSwitcher(child: activeScreen)),
                ],
              ),
            ),
          ],
        ).crossAlign(.stretch),
      );
    }

    return Scaffold()
        .appBar(
          AppBar(
            title: Text(active.titleLabel).weight(.w800),
            actions: [
              if (_index == 0)
                IconButton(
                  icon: const Icon(Icons.person_outline_rounded),
                  onPressed: () {},
                ),
            ],
          ),
        )
        .body(ExpressivePageSwitcher(child: activeScreen))
        .bottomNavigation(
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _select,
            destinations: [
              for (final d in destinations)
                NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: d.navLabel,
                ),
            ],
          ),
        );
  }
}

class _ExpressiveSideRail extends StatelessWidget {
  const _ExpressiveSideRail({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<_Destination> destinations;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surfaceContainerLowest,
      child: SizedBox(
        width: _railWidth,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 10),
              child: ExpressiveIconContainer(
                icon: Icons.alt_route_rounded,
                size: 52,
                radius: 20,
                color: colors.primaryContainer,
                foregroundColor: colors.onPrimaryContainer,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  for (var i = 0; i < destinations.length; i++)
                    _ExpressiveRailDestination(
                      destination: destinations[i],
                      selected: i == selectedIndex,
                      onTap: () => onDestinationSelected(i),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpressiveRailDestination extends StatefulWidget {
  const _ExpressiveRailDestination({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ExpressiveRailDestination> createState() =>
      _ExpressiveRailDestinationState();
}

class _ExpressiveRailDestinationState extends State<_ExpressiveRailDestination>
    with TickerProviderStateMixin {
  late final SingleMotionController _widthCtrl;
  late final SingleMotionController _scaleCtrl;
  late final SingleMotionController _iconScaleCtrl;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _widthCtrl = SingleMotionController(
      motion: M3EMotion.expressiveSpatialDefault.toMotion(),
      vsync: this,
      initialValue: widget.selected ? 1 : 0,
    );
    _scaleCtrl = SingleMotionController(
      motion: M3EMotion.expressiveSpatialFast.toMotion(),
      vsync: this,
      initialValue: widget.selected ? 1 : 0,
    );
    _iconScaleCtrl = SingleMotionController(
      motion: M3EMotion.expressiveEffectsFast.toMotion(),
      vsync: this,
      initialValue: widget.selected ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(_ExpressiveRailDestination oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      _widthCtrl.animateTo(widget.selected ? 1 : 0);
      _scaleCtrl.animateTo(widget.selected ? 1 : 0);
      _iconScaleCtrl.animateTo(widget.selected ? 1 : 0);
    }
  }

  @override
  void dispose() {
    _widthCtrl.dispose();
    _scaleCtrl.dispose();
    _iconScaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = widget.selected
        ? colors.onSecondaryContainer
        : colors.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.destination.titleLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _widthCtrl,
              _scaleCtrl,
              _iconScaleCtrl,
            ]),
            child: _RailLabel(
              widget.destination.navLabel,
              selected: widget.selected,
            ),
            builder: (context, child) {
              final widthProgress = _widthCtrl.value;
              final scaleProgress = _scaleCtrl.value;
              final iconScaleProgress = _iconScaleCtrl.value;

              final width = _lerpDouble(48, _railIndicatorWidth, widthProgress);
              final indicatorRadius = _lerpDouble(18, 100, widthProgress);
              final iconScale = _lerpDouble(1, 1.08, iconScaleProgress);
              final iconSize = _lerpDouble(23, 26, iconScaleProgress);
              final pressScale = _pressed ? .94 : 1.0;
              final bgAlpha = scaleProgress;

              return SizedBox(
                height: _railDestinationHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.scale(
                      scale: pressScale,
                      child: Container(
                        width: width,
                        height: _railIndicatorHeight,
                        decoration: BoxDecoration(
                          color: Color.lerp(
                            Colors.transparent,
                            colors.secondaryContainer,
                            bgAlpha,
                          ),
                          borderRadius: BorderRadius.circular(indicatorRadius),
                        ),
                        child: Transform.scale(
                          scale: iconScale,
                          child: Icon(
                            widget.selected
                                ? widget.destination.selectedIcon
                                : widget.destination.icon,
                            color: foreground,
                            size: iconSize,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    child!,
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  double _lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

class _RailLabel extends StatelessWidget {
  const _RailLabel(this.label, {required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: _railLabelWidth,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: AnimatedDefaultTextStyle(
            duration: expressiveFastDuration,
            curve: expressiveCurve,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
              color: selected
                  ? colors.onSecondaryContainer
                  : colors.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              letterSpacing: 0,
            ),
            child: Text(label, maxLines: 1),
          ),
        ),
      ),
    );
  }
}
