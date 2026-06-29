import 'dart:io';

import 'package:mesh_market/core/pairing.dart';
import 'package:mesh_market/transport/lan_signaling.dart';
import 'package:mesh_market/transport/signaling.dart';
import 'package:test/test.dart';

PairingPayload _payload(String id, String name) => PairingPayload(
  deviceId: id,
  name: name,
  signingKey: const [1, 2],
  agreementKey: const [3, 4],
);

void main() {
  test('offer, answer and ice round-trip through encode/decode', () {
    final offer =
        SignalMessage.decode(const SdpSignal.offer('o').encode()) as SdpSignal;
    expect(offer.isOffer, isTrue);
    expect(offer.sdp, equals('o'));

    final answer =
        SignalMessage.decode(const SdpSignal.answer('a').encode()) as SdpSignal;
    expect(answer.isOffer, isFalse);

    final ice =
        SignalMessage.decode(const IceSignal('cand', 'mid', 2).encode())
            as IceSignal;
    expect(ice.candidate, equals('cand'));
    expect(ice.sdpMid, equals('mid'));
    expect(ice.sdpMLineIndex, equals(2));
  });

  test('hello round-trips peer metadata', () {
    final decoded =
        SignalMessage.decode(
              SignalHello(
                'infohash',
                'DEVICE1',
                payload: _payload('DEVICE1', 'Tablet'),
                syncPort: 49323,
              ).encode(),
            )
            as SignalHello;

    expect(decoded.deviceId, equals('DEVICE1'));
    expect(decoded.payload?.name, equals('Tablet'));
    expect(decoded.syncPort, equals(49323));
  });

  test('client and server exchange signals over loopback TCP', () async {
    final server = LanSignalingServer(0);
    await server.start();
    final accepted = server.connections.first;
    final client = await connectLanSignaling(
      InternetAddress.loopbackIPv4,
      server.boundPort,
    );
    final serverSide = await accepted;

    final serverReceived = serverSide.incoming.first;
    await client.send(const SdpSignal.offer('hello-sdp'));
    expect((await serverReceived as SdpSignal).sdp, equals('hello-sdp'));

    final clientReceived = client.incoming.first;
    await serverSide.send(const IceSignal('c', 'm', 1));
    expect((await clientReceived as IceSignal).candidate, equals('c'));

    await client.close();
    await serverSide.close();
    await server.stop();
  });
}
