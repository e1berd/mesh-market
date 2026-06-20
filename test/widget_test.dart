import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:point_machine/app.dart';
import 'package:point_machine/core/identity.dart';
import 'package:point_machine/core/pairing.dart';
import 'package:point_machine/state/identity_provider.dart';
import 'package:point_machine/state/peers_provider.dart';

void main() {
  testWidgets('boots into the devices destination', (tester) async {
    final identity = await _fakeIdentity();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          identityProvider.overrideWithValue(AsyncData(identity)),
          deviceNameProvider.overrideWithBuild(
            (ref, notifier) => 'Test machine',
          ),
          pairedPeersProvider.overrideWithBuild(
            (ref, notifier) => const <PairingPayload>[],
          ),
        ],
        child: const PointMachineApp(),
      ),
    );
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('Paired devices').evaluate().isNotEmpty) break;
    }

    expect(find.text('Devices'), findsWidgets);
    expect(find.text('Paired devices'), findsOneWidget);
  });
}

Future<DeviceIdentity> _fakeIdentity() async {
  final signing = await Ed25519().newKeyPairFromSeed(
    List<int>.generate(32, (i) => i),
  );
  final agreement = await X25519().newKeyPairFromSeed(
    List<int>.generate(32, (i) => 31 - i),
  );
  final signingPublicKey = await signing.extractPublicKey();
  final agreementPublicKey = await agreement.extractPublicKey();

  return DeviceIdentity(
    id: 'TESTDEVICE',
    signing: signing,
    agreement: agreement,
    signingPublicKey: signingPublicKey,
    agreementPublicKey: agreementPublicKey,
  );
}
