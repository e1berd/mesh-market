import 'package:declar_ui/declar_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/pairing.dart';
import '../../i18n/strings.g.dart';
import '../../state/identity_provider.dart';
import '../../state/peers_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/expressive.dart';

class PairScreen extends ConsumerWidget {
  const PairScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(identityProvider);
    final name = ref.watch(deviceNameProvider);
    final colors = context.colors;

    return SafeArea(
      top: false,
      child: ExpressiveSwitcher(
        child: identity.when(
          loading: () => const Center(
            key: ValueKey('pair-loading'),
            child: CircularProgressIndicator(),
          ),
          error: (error, _) => EmptyState(
            key: const ValueKey('pair-error'),
            icon: Icons.error_outline_rounded,
            title: context.t.devices.errorLoad,
            message: '$error',
          ),
          data: (device) => name.when(
            loading: () => const Center(
              key: ValueKey('pair-name-loading'),
              child: CircularProgressIndicator(),
            ),
            error: (error, _) => EmptyState(
              key: const ValueKey('pair-name-error'),
              icon: Icons.error_outline_rounded,
              title: 'Could not load device name',
              message: '$error',
            ),
            data: (deviceName) => Center(
              key: const ValueKey('pair-data'),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: ExpressiveReveal(
                    child: Column(
                      mainAxisSize: .min,
                      children: [
                        AnimatedContainer(
                          duration: expressiveDuration,
                          curve: expressiveCurve,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(36),
                            border: Border.all(
                              color: colors.outlineVariant.withValues(
                                alpha: .35,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colors.surface,
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                child: QrImageView(
                                  data: PairingPayload.ofDevice(
                                    device,
                                    deviceName,
                                  ).encode(),
                                  size: 220,
                                  padding: const EdgeInsets.all(12),
                                  backgroundColor: colors.surface,
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
                            Text(context.t.pair.scanHint)
                                .size(18)
                                .weight(.w800)
                                .color(colors.onSurface)
                                .align(.center),
                              Text(deviceName)
                                  .size(13)
                                  .weight(.w600)
                                  .color(colors.onSurfaceVariant)
                                  .align(.center)
                                  .padding(top: 6),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      M3EButton.icon(
                        onPressed: () => _scanDevice(context, ref, device.id),
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                        label: Text(context.t.pair.scanButton),
                        style: M3EButtonStyle.outlined,
                        size: .md,
                      ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _scanDevice(
    BuildContext context,
    WidgetRef ref,
    String currentDeviceId,
  ) async {
    final raw = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _PairingScannerPage()),
    );
    if (raw == null || !context.mounted) return;

    try {
      final peer = PairingPayload.decode(raw);
      if (peer.deviceId == currentDeviceId) {
        context.showSnackBar(context.t.pair.selfPairError);
        return;
      }

      await ref.read(pairedPeersProvider.future);
      await ref.read(pairedPeersProvider.notifier).add(peer);
      if (context.mounted) {
        context.showSnackBar(context.t.pair.paired(name: peer.name));
      }
    } catch (_) {
      if (context.mounted) {
        context.showSnackBar(context.t.pair.invalidQr);
      }
    }
  }
}

class _PairingScannerPage extends StatefulWidget {
  const _PairingScannerPage();

  @override
  State<_PairingScannerPage> createState() => _PairingScannerPageState();
}

class _PairingScannerPageState extends State<_PairingScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );

  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: Text(context.t.pair.scanButton),
        actions: [
          IconButton(
            tooltip: context.t.pair.toggleFlashlight,
            onPressed: _controller.toggleTorch,
            icon: const Icon(Icons.flashlight_on_rounded),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Center(child: _ScanFrame(color: colors.primary)),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: ExpressiveReveal(
                offset: 28,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHigh.withValues(alpha: .94),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: Text('Point the camera at another device QR code')
                      .size(15)
                      .weight(.w800)
                      .color(colors.onSurface)
                      .align(.center),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw.isEmpty) continue;

      _handled = true;
      Navigator.of(context).pop(raw);
      return;
    }
  }
}

class _ScanFrame extends StatelessWidget {
  const _ScanFrame({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: .92, end: 1),
      duration: expressiveDuration,
      curve: expressiveCurve,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        width: 268,
        height: 268,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 4),
          borderRadius: BorderRadius.circular(36),
        ),
        child: Center(
          child: Container(
            width: 212,
            height: 212,
            decoration: BoxDecoration(
              border: Border.all(color: color.withValues(alpha: .38), width: 2),
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
      ),
    );
  }
}
