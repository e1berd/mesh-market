import 'package:declar_ui/declar_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/activity_screen.dart';
import 'screens/devices_screen.dart';
import 'screens/folders_screen.dart';
import 'screens/pair_screen.dart';
import 'screens/settings_screen.dart';

class _Destination {
  const _Destination(this.icon, this.selectedIcon, this.label, this.screen);

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget screen;
}

const _destinations = [
  _Destination(
      Icons.devices_outlined, Icons.devices_rounded, 'Devices', DevicesScreen()),
  _Destination(
      Icons.folder_outlined, Icons.folder_rounded, 'Folders', FoldersScreen()),
  _Destination(Icons.qr_code_scanner_outlined, Icons.qr_code_scanner_rounded,
      'Pair', PairScreen()),
  _Destination(Icons.sync_outlined, Icons.sync_rounded, 'Activity',
      ActivityScreen()),
  _Destination(Icons.settings_outlined, Icons.settings_rounded, 'Settings',
      SettingsScreen()),
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
    final active = _destinations[_index];
    final colors = context.colors;

    if (context.width >= 720) {
      return Scaffold().body(
        Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: _select,
              labelType: .all,
              leading: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Icon(
                  Icons.alt_route_rounded,
                  size: 28,
                  color: colors.primary,
                ),
              ),
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
            VerticalDivider(width: 1, color: colors.outlineVariant),
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(active.label)
                          .size(28)
                          .weight(.w800)
                          .letterSpacing(-0.5),
                    ),
                  ),
                  Expanded(child: active.screen),
                ],
              ),
            ),
          ],
        ).crossAlign(.stretch),
      );
    }

    return Scaffold()
        .appBar(AppBar(
          title: Text(active.label).weight(.w800),
          actions: [
            if (_index == 0)
              IconButton(
                icon: const Icon(Icons.person_outline_rounded),
                onPressed: () {},
              ),
          ],
        ))
        .body(active.screen)
        .bottomNavigation(
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _select,
            destinations: [
              for (final d in _destinations)
                NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: d.label,
                ),
            ],
          ),
        );
  }
}
