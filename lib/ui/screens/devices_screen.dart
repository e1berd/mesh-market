import 'package:declar_ui/declar_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_core/m3e_core.dart';

import '../../state/identity_provider.dart';
import '../widgets/empty_state.dart';

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(identityProvider);
    final name = ref.watch(deviceNameProvider);
    final colors = context.colors;

    return identity.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Could not load identity',
        message: '$error',
      ),
      data: (device) => Column(
        crossAxisAlignment: .stretch,
        children: [
          M3ECardList(
            itemCount: 1,
            itemBuilder: (ctx, i) => _thisDevice(context, name, device.id),
            outerRadius: 28,
            gap: 0,
            color: colors.surfaceContainerHigh,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Text('Paired devices')
                .size(12)
                .weight(.w800)
                .letterSpacing(0.8)
                .color(colors.primary),
          ),
          const Expanded(
            child: EmptyState(
              icon: Icons.devices_other_rounded,
              title: 'No paired devices',
              message: 'Open Pair to connect another device.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _thisDevice(BuildContext context, String name, String id) {
    final colors = context.colors;
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child:
              Icon(Icons.computer_rounded, color: colors.onPrimaryContainer),
        ).padding(right: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Text(name).size(16).weight(.w700),
              Text('This device')
                  .size(12)
                  .color(colors.onSurfaceVariant),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colors.tertiaryContainer,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text('Online')
              .size(11)
              .weight(.w700)
              .color(colors.onTertiaryContainer),
        ),
      ],
    );
  }
}
