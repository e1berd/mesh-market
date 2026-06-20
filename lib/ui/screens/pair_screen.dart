import 'package:declar_ui/declar_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/pairing.dart';
import '../../state/identity_provider.dart';
import '../widgets/empty_state.dart';

class PairScreen extends ConsumerWidget {
  const PairScreen({super.key});

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
      data: (device) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            mainAxisSize: .min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: QrImageView(
                  data: PairingPayload.ofDevice(device, name).encode(),
                  size: 220,
                  padding: const EdgeInsets.all(12),
                  backgroundColor: colors.surfaceContainerHigh,
                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.circle,
                    color: colors.onSurface,
                  ),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.circle,
                    color: colors.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Scan this code on another device')
                  .size(16)
                  .weight(.w600)
                  .color(colors.onSurface)
                  .align(.center),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: device.id));
                  context.showSnackBar('Device ID copied');
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fingerprint_rounded,
                          size: 16, color: colors.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(device.id)
                          .size(13)
                          .color(colors.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Icon(Icons.copy_rounded,
                          size: 14, color: colors.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              M3EButton.icon(
                onPressed: () =>
                    context.showSnackBar('Camera pairing coming soon'),
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Scan a device'),
                style: M3EButtonStyle.outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
