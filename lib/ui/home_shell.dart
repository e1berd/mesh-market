import 'package:declar_ui/declar_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/strings.g.dart';
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

  void _select(int next) => setState(() => _index = next);

  @override
  Widget build(BuildContext context) {
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

class _ExpressiveRailDestination extends StatelessWidget {
  const _ExpressiveRailDestination({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = selected
        ? colors.onSecondaryContainer
        : colors.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.titleLabel,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: SizedBox(
            height: _railDestinationHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: expressiveFastDuration,
                  curve: expressiveCurve,
                  width: selected ? _railIndicatorWidth : 48,
                  height: _railIndicatorHeight,
                  decoration: BoxDecoration(
                    color: selected
                        ? colors.secondaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(selected ? 100 : 18),
                  ),
                  child: AnimatedScale(
                    scale: selected ? 1.08 : 1,
                    duration: expressiveFastDuration,
                    curve: expressiveCurve,
                    child: Icon(
                      selected ? destination.selectedIcon : destination.icon,
                      color: foreground,
                      size: selected ? 26 : 23,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                _RailLabel(destination.navLabel, selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
