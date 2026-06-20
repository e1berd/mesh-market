import 'dart:io';

import 'package:point_machine/core/identity.dart';
import 'package:point_machine/core/pairing.dart';
import 'package:test/test.dart';

void main() {
  test('pairing payload round-trips and carries the device public keys', () async {
    final identity = await IdentityService(
      File('${Directory.systemTemp.createTempSync().path}/identity.json'),
    ).loadOrCreate();

    final decoded =
        PairingPayload.decode(PairingPayload.ofDevice(identity, 'laptop').encode());

    expect(decoded.deviceId, equals(identity.id));
    expect(decoded.name, equals('laptop'));
    expect(decoded.signingKey, equals(identity.signingPublicKey.bytes));
    expect(decoded.agreementKey, equals(identity.agreementPublicKey.bytes));
  });
}
