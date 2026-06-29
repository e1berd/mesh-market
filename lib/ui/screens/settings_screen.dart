import 'package:declar_ui/declar_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_core/m3e_core.dart';

import '../../i18n/strings.g.dart';
import '../widgets/expressive.dart';
import 'settings/appearance_settings_screen.dart';
import 'settings/discovery_settings_screen.dart';
import 'settings/logs_settings_screen.dart';
import 'settings/signaling_settings_screen.dart';
import 'settings/sync_settings_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t.settings;
    final colors = context.colors;
    final entries = [
      _SettingsEntry(
        icon: Icons.palette_rounded,
        title: t.appearance,
        subtitle: t.appearanceSubtitle,
        builder: () => const AppearanceSettingsScreen(),
      ),
      _SettingsEntry(
        icon: Icons.sync_rounded,
        title: t.syncTitle,
        subtitle: t.syncSubtitle,
        builder: () => const SyncSettingsScreen(),
      ),
      _SettingsEntry(
        icon: Icons.travel_explore_rounded,
        title: t.discovery,
        subtitle: t.discoverySubtitle,
        builder: () => const DiscoverySettingsScreen(),
      ),
      _SettingsEntry(
        icon: Icons.receipt_long_rounded,
        title: t.logsTitle,
        subtitle: t.logsSubtitle,
        builder: () => const LogsSettingsScreen(),
      ),
      _SettingsEntry(
        icon: Icons.cell_tower_rounded,
        title: t.signaling,
        subtitle: t.signalingSubtitle,
        builder: () => const SignalingSettingsScreen(),
      ),
    ];

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        clipBehavior: Clip.hardEdge,
        child: ExpressiveResponsiveCenter(
          maxWidth: 760,
          child: ExpressiveReveal(
            child: M3ECardList(
              itemCount: entries.length,
              itemBuilder: (context, i) => _SettingsRow(entry: entries[i]),
              onTap: (i) => context.push(entries[i].builder()),
              semanticLabelBuilder: (i) => entries[i].title,
              outerRadius: expressiveListOuterRadius,
              innerRadius: expressiveListInnerRadius,
              gap: expressiveListGap,
              color: colors.surfaceContainerHigh,
              padding: expressiveListPadding,
              margin: expressiveListMargin,
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsEntry {
  const _SettingsEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.builder,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget Function() builder;
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.entry});

  final _SettingsEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        ExpressiveIconContainer(
          icon: entry.icon,
          color: colors.secondaryContainer,
          foregroundColor: colors.onSecondaryContainer,
        ).padding(right: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Text(entry.title).size(16).weight(.w700),
              Text(entry.subtitle)
                  .size(12)
                  .color(colors.onSurfaceVariant)
                  .maxLines(2)
                  .overflow(.ellipsis),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
      ],
    );
  }
}
