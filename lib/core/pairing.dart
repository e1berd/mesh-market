import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import 'identity.dart';

class PairingPayload {
  const PairingPayload({
    required this.deviceId,
    required this.name,
    required this.signingKey,
    required this.agreementKey,
  });

  factory PairingPayload.ofDevice(DeviceIdentity identity, String name) =>
      PairingPayload(
        deviceId: identity.id,
        name: name,
        signingKey: identity.signingPublicKey.bytes,
        agreementKey: identity.agreementPublicKey.bytes,
      );

  factory PairingPayload.fromJson(Map<String, Object?> json) => PairingPayload(
        deviceId: json['id'] as String,
        name: json['name'] as String,
        signingKey: base64Decode(json['sign'] as String),
        agreementKey: base64Decode(json['agree'] as String),
      );

  factory PairingPayload.decode(String raw) =>
      PairingPayload.fromJson((jsonDecode(raw) as Map).cast<String, Object?>());

  final String deviceId;
  final String name;
  final List<int> signingKey;
  final List<int> agreementKey;

  SimplePublicKey signingPublicKey() =>
      SimplePublicKey(signingKey, type: KeyPairType.ed25519);

  SimplePublicKey agreementPublicKey() =>
      SimplePublicKey(agreementKey, type: KeyPairType.x25519);

  Map<String, Object?> toJson() => {
        'id': deviceId,
        'name': name,
        'sign': base64Encode(signingKey),
        'agree': base64Encode(agreementKey),
      };

  String encode() => jsonEncode(toJson());
}
