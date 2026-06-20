import 'package:declar_ui/declar_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_core/m3e_core.dart';

import '../../state/app_providers.dart';
import '../widgets/ice_server_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(configProvider);
    final notifier = ref.read(configProvider.notifier);
    final colors = context.colors;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          const SizedBox(height: 8),
          _Section(
            title: 'Appearance',
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: M3EToggleButtonGroup(
                  actions: const [
                    M3EToggleButtonGroupAction(
                      icon: Icon(Icons.brightness_auto_rounded),
                      label: Text('System'),
                    ),
                    M3EToggleButtonGroupAction(
                      icon: Icon(Icons.light_mode_rounded),
                      label: Text('Light'),
                    ),
                    M3EToggleButtonGroupAction(
                      icon: Icon(Icons.dark_mode_rounded),
                      label: Text('Dark'),
                    ),
                  ],
                  type: .connected,
                  size: .sm,
                  style: .tonal,
                  selectedIndex: config.themeMode.index,
                  onSelectedIndexChanged: (i) {
                    if (i != null) notifier.setThemeMode(ThemeMode.values[i]);
                  },
                ),
              ),
            ],
          ),
          _Section(
            title: 'Discovery',
            children: [
              _SettingTile(
                icon: Icons.wifi_rounded,
                title: 'Local network (mDNS)',
                subtitle: 'Find peers on the same network',
                trailing: Switch(
                  value: config.lanDiscovery,
                  onChanged: notifier.toggleLanDiscovery,
                ),
              ),
              _SettingTile(
                icon: Icons.public_rounded,
                title: 'Internet (DHT)',
                subtitle: 'Find peers across networks',
                trailing: Switch(
                  value: config.dhtDiscovery,
                  onChanged: notifier.toggleDhtDiscovery,
                ),
              ),
              _SettingTile(
                icon: Icons.sync_rounded,
                title: 'Sync in background',
                subtitle: 'Keep syncing when app is not focused',
                trailing: Switch(
                  value: config.syncInBackground,
                  onChanged: notifier.toggleBackground,
                ),
              ),
            ],
          ),
          _Section(
            title: 'Signaling (STUN / TURN)',
            children: [
              if (config.iceServers.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text('Using default STUN server')
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
                  subtitle: config.iceServers[i].isTurn ? 'TURN' : 'STUN',
                  trailing: IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => notifier.removeIceServer(i),
                  ),
                ),
            ],
          ),
          M3EButton.icon(
            onPressed: () async {
              final server = await showIceServerDialog(context);
              if (server != null) notifier.addIceServer(server);
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add server'),
            style: .tonal,
          ).padding(horizontal: 16, top: 12),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(title)
              .size(12)
              .weight(.w800)
              .letterSpacing(0.8)
              .color(colors.primary),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: .min,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: 56,
                    endIndent: 0,
                    color: colors.outlineVariant.withValues(alpha: .4),
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ],
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
      leading: Icon(icon, color: colors.onSurfaceVariant),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing,
    );
  }
}
