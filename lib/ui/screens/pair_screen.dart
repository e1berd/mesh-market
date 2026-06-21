import 'package:declar_ui/declar_ui.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/identity.dart';
import '../../core/pairing.dart';
import '../../i18n/strings.g.dart';
import '../../state/identity_provider.dart';
import '../../state/incoming_pair_provider.dart';
import '../../state/nearby_devices_provider.dart';
import '../../state/pairing_controller.dart';
import '../../state/peers_provider.dart';
import '../../transport/lan_beacon.dart';
import '../widgets/empty_state.dart';
import '../widgets/expressive.dart';
import '../widgets/remote_code_field.dart';

const _gap = 16.0;

class PairScreen extends ConsumerStatefulWidget {
  const PairScreen({super.key});

  @override
  ConsumerState<PairScreen> createState() => _PairScreenState();
}

class _PairScreenState extends ConsumerState<PairScreen> {
  final _handled = <IncomingPair>{};
  bool _revealed = false;
  bool _scanning = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<List<IncomingPair>>(incomingPairProvider, (_, next) {
      for (final pending in next) {
        if (_handled.add(pending)) _confirm(pending);
      }
    });

    final identity = ref.watch(identityProvider);
    final name = ref.watch(deviceNameProvider);

    return SafeArea(
      top: false,
      child: ExpressiveSwitcher(
        child: identity.when(
          loading: () => const Center(
            key: ValueKey('pair-loading'),
            child: ExpressiveLoadingIndicator(),
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
              child: ExpressiveLoadingIndicator(),
            ),
            error: (error, _) => EmptyState(
              key: const ValueKey('pair-name-error'),
              icon: Icons.error_outline_rounded,
              title: context.t.devices.errorLoad,
              message: '$error',
            ),
            data: (deviceName) => _body(context, device, deviceName),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, DeviceIdentity device, String deviceName) {
    if (context.width >= 900) {
      return Padding(
        key: const ValueKey('pair-data'),
        padding: const EdgeInsets.all(_gap),
        child: Row(
          crossAxisAlignment: .stretch,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: .stretch,
                spacing: _gap,
                children: [
                  Expanded(child: _qrCard(context, device, deviceName, fill: true)),
                  _yourCode(context, device.id),
                ],
              ),
            ),
            const SizedBox(width: _gap),
            Expanded(
              child: Column(
                crossAxisAlignment: .stretch,
                spacing: _gap,
                children: [
                  _remote(context, device.id),
                  Expanded(child: _nearbyCard(context, device.id)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      key: const ValueKey('pair-data'),
      padding: const EdgeInsets.all(_gap),
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: _gap,
        children: [
          _qrCard(context, device, deviceName, fill: false),
          _yourCode(context, device.id),
          _remote(context, device.id),
          _scanButton(context, device.id),
          _nearbySection(context, device.id),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, Widget child) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(28),
          border:
              Border.all(color: context.colors.outlineVariant.withValues(alpha: .32)),
        ),
        child: child,
      );

  Widget _sectionTitle(BuildContext context, String title) => Text(title)
      .size(13)
      .weight(.w800)
      .letterSpacing(.5)
      .color(context.colors.primary);

  Widget _qrCard(BuildContext context, DeviceIdentity device, String deviceName,
      {required bool fill}) {
    final colors = context.colors;
    final data = PairingPayload.ofDevice(device, deviceName).encode();
    final square = _qrSquare(context, data, fill: fill);
    return ExpressiveReveal(
      child: _card(
        context,
        Column(
          crossAxisAlignment: .stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton.filledTonal(
                tooltip: context.t.pair.fullscreen,
                onPressed: () => _showFullscreen(context, data),
                icon: const Icon(Icons.fullscreen_rounded),
              ),
            ),
            const SizedBox(height: 12),
            if (fill) Expanded(child: square) else square,
            const SizedBox(height: 18),
            Text(context.t.pair.scanHint)
                .size(17)
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
    );
  }

  Widget _qrSquare(BuildContext context, String data, {required bool fill}) {
    final colors = context.colors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final side = fill
            ? (width < constraints.maxHeight ? width : constraints.maxHeight)
            : (width < 260 ? width : 260.0);
        return Center(
          child: GestureDetector(
            onTap: () => _showFullscreen(context, data),
            child: Container(
              width: side,
              height: side,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(28),
              ),
              child: _qrImage(context, data, side - 32),
            ),
          ),
        );
      },
    );
  }

  Widget _qrImage(BuildContext context, String data, double size) {
    final colors = context.colors;
    return QrImageView(
      data: data,
      size: size,
      padding: const EdgeInsets.all(8),
      backgroundColor: colors.surface,
      eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.circle, color: colors.onSurface),
      dataModuleStyle: QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.circle,
        color: colors.onSurface,
      ),
    );
  }

  void _showFullscreen(BuildContext context, String data) {
    final side = MediaQuery.sizeOf(context).shortestSide * 0.82;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .9),
      builder: (dialogContext) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pop(dialogContext),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: QrImageView(
              data: data,
              size: side,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.circle,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.circle,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _yourCode(BuildContext context, String code) {
    final colors = context.colors;
    return ExpressiveReveal(
      child: _card(
        context,
        Column(
          crossAxisAlignment: .start,
          children: [
            _sectionTitle(context, context.t.pair.yourCodeTitle),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(_revealed ? code : _mask(code))
                  .size(15)
                  .weight(.w600)
                  .font('monospace')
                  .color(colors.onSurface)
                  .maxLines(1)
                  .overflow(.ellipsis),
            ),
            const SizedBox(height: 8),
            Text(context.t.pair.yourCodeHint)
                .size(12)
                .color(colors.onSurfaceVariant),
            const SizedBox(height: 10),
            Row(
              children: [
                M3EButton.icon(
                  onPressed: () => setState(() => _revealed = !_revealed),
                  icon: Icon(_revealed
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded),
                  label: Text(_revealed
                      ? context.t.pair.hideCode
                      : context.t.pair.showCode),
                  style: M3EButtonStyle.text,
                  size: .sm,
                ),
                const SizedBox(width: 8),
                M3EButton.icon(
                  onPressed: () => _copy(context, code),
                  icon: const Icon(Icons.copy_rounded),
                  label: Text(context.t.pair.copyCode),
                  style: M3EButtonStyle.text,
                  size: .sm,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _remote(BuildContext context, String selfId) => ExpressiveReveal(
        child: _card(
          context,
          Column(
            crossAxisAlignment: .start,
            children: [
              _sectionTitle(context, context.t.pair.remoteCodeTitle),
              const SizedBox(height: 14),
              RemoteCodeField(
                hint: context.t.pair.remoteCodeHint,
                action: context.t.pair.pairAction,
                validator: (code) {
                  if (code.isEmpty) return context.t.pair.codeEmpty;
                  if (code == selfId) return context.t.pair.selfPairError;
                  return null;
                },
                onSubmit: (code) => _pairByCode(context, code),
              ),
            ],
          ),
        ),
      );

  Widget _nearbyCard(BuildContext context, String selfId) {
    final candidates = _candidates(selfId);
    return _card(
      context,
      Column(
        crossAxisAlignment: .start,
        children: [
          _nearbyHeader(context),
          const SizedBox(height: 8),
          Expanded(
            child: !_scanning
                ? _paused(context)
                : candidates.isEmpty
                    ? _searching(context)
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: .stretch,
                          children: [
                            for (final peer in candidates)
                              _nearbyTile(context, peer),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _nearbySection(BuildContext context, String selfId) {
    final candidates = _candidates(selfId);
    return _card(
      context,
      Column(
        crossAxisAlignment: .stretch,
        children: [
          _nearbyHeader(context),
          const SizedBox(height: 8),
          if (!_scanning)
            _pausedTile(context)
          else if (candidates.isEmpty)
            _searchingTile(context)
          else
            for (final peer in candidates) _nearbyTile(context, peer),
        ],
      ),
    );
  }

  List<LanPeer> _candidates(String selfId) {
    if (!_scanning) return const [];
    final nearby = ref.watch(nearbyDevicesProvider).value ?? const <LanPeer>[];
    final paired = ref.watch(pairedPeersProvider).value ?? const <PairingPayload>[];
    final pairedIds = {for (final peer in paired) peer.deviceId};
    return [
      for (final peer in nearby)
        if (peer.deviceId != selfId && !pairedIds.contains(peer.deviceId)) peer,
    ];
  }

  Widget _nearbyHeader(BuildContext context) => Row(
        children: [
          Expanded(child: _sectionTitle(context, context.t.pair.nearbyTitle)),
          IconButton(
            tooltip:
                _scanning ? context.t.pair.pauseScan : context.t.pair.resumeScan,
            onPressed: () => setState(() => _scanning = !_scanning),
            icon: Icon(_scanning
                ? Icons.stop_circle_outlined
                : Icons.play_circle_outline_rounded),
          ),
        ],
      );

  Widget _paused(BuildContext context) => Center(
        child: Column(
          mainAxisSize: .min,
          children: [
            Icon(Icons.pause_circle_outline_rounded,
                size: 40, color: context.colors.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(context.t.pair.scanPaused)
                .size(13)
                .color(context.colors.onSurfaceVariant)
                .align(.center),
          ],
        ).padding(all: 24),
      );

  Widget _pausedTile(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(Icons.pause_circle_outline_rounded,
                color: context.colors.onSurfaceVariant),
            const SizedBox(width: 14),
            Text(context.t.pair.scanPaused)
                .size(13)
                .color(context.colors.onSurfaceVariant),
          ],
        ),
      );

  Widget _searching(BuildContext context) => Center(
        child: Column(
          mainAxisSize: .min,
          children: [
            const ExpressiveLoadingIndicator(),
            const SizedBox(height: 16),
            Text(context.t.pair.nearbySearching)
                .size(13)
                .color(context.colors.onSurfaceVariant)
                .align(.center),
          ],
        ).padding(all: 24),
      );

  Widget _searchingTile(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            const ExpressiveLoadingIndicator(
              constraints: BoxConstraints.tightFor(width: 24, height: 24),
            ),
            const SizedBox(width: 14),
            Text(context.t.pair.nearbySearching)
                .size(13)
                .color(context.colors.onSurfaceVariant),
          ],
        ),
      );

  Widget _nearbyTile(BuildContext context, LanPeer peer) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const ExpressiveIconContainer(
          icon: Icons.devices_rounded,
          size: 44,
          radius: 14,
        ),
        title: Text(peer.payload.name).weight(.w700),
        subtitle: Text(peer.address.address),
        trailing: M3EButton(
          onPressed: () => _pair(context, peer.payload),
          style: M3EButtonStyle.tonal,
          size: .sm,
          child: Text(context.t.pair.pairAction),
        ),
      );

  Widget _scanButton(BuildContext context, String selfId) => M3EButton.icon(
        onPressed: () => _scan(context, selfId),
        icon: const Icon(Icons.qr_code_scanner_rounded),
        label: Text(context.t.pair.scanButton),
        style: M3EButtonStyle.outlined,
        size: .md,
      );

  String _mask(String code) {
    final tail = code.length <= 6 ? code : code.substring(code.length - 6);
    return '••••••$tail';
  }

  void _copy(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    context.showSnackBar(context.t.pair.codeCopied);
  }

  Future<void> _pair(BuildContext context, PairingPayload peer) async {
    context.showSnackBar(context.t.pair.pairing);
    final outcome = await ref.read(pairingControllerProvider).pairByPayload(peer);
    if (!context.mounted) return;
    context.showSnackBar(switch (outcome) {
      PairOutcome.paired => context.t.pair.paired(name: peer.name),
      PairOutcome.storedLocally => context.t.pair.storedLocally,
      PairOutcome.failed => context.t.pair.pairFailed,
    });
  }

  Future<void> _pairByCode(BuildContext context, String code) async {
    context.showSnackBar(context.t.pair.pairing);
    final outcome = await ref.read(pairingControllerProvider).pairByCode(code);
    if (!context.mounted) return;
    context.showSnackBar(outcome == PairOutcome.paired
        ? context.t.pair.pairedDone
        : context.t.pair.pairFailed);
  }

  Future<void> _scan(BuildContext context, String selfId) async {
    final raw = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _PairingScannerPage()),
    );
    if (raw == null || !context.mounted) return;
    try {
      final peer = PairingPayload.decode(raw);
      if (peer.deviceId == selfId) {
        context.showSnackBar(context.t.pair.selfPairError);
        return;
      }
      await _pair(context, peer);
    } on Object {
      if (context.mounted) context.showSnackBar(context.t.pair.invalidQr);
    }
  }

  Future<void> _confirm(IncomingPair pending) async {
    final colors = context.colors;
    final accept = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.t.pair.incomingTitle),
        content: Column(
          mainAxisSize: .min,
          children: [
            Text(context.t.pair.incomingBody(name: pending.payload.name)),
            const SizedBox(height: 18),
            Text(context.t.pair.verificationCode)
                .size(12)
                .weight(.w700)
                .color(colors.onSurfaceVariant),
            Text(pending.code)
                .size(34)
                .weight(.w800)
                .color(colors.primary)
                .letterSpacing(4),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.t.pair.reject),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.t.pair.accept),
          ),
        ],
      ),
    );
    ref.read(incomingPairProvider.notifier).resolve(pending, accept ?? false);
    _handled.remove(pending);
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
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: Text(context.t.pair.scanInstruction)
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
      builder: (context, value, child) =>
          Transform.scale(scale: value, child: child),
      child: Container(
        width: 268,
        height: 268,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 4),
          borderRadius: BorderRadius.circular(36),
        ),
      ),
    );
  }
}
