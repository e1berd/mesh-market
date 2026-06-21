import 'dart:io';

import 'package:point_machine/core/pairing.dart';
import 'package:point_machine/transport/lan_signaling.dart';
import 'package:point_machine/transport/pairing_code.dart';
import 'package:point_machine/transport/signaling.dart';
import 'package:test/test.dart';

PairingPayload _payload(String id) => PairingPayload(
      deviceId: id,
      name: 'dev-$id',
      signingKey: const [1, 2],
      agreementKey: const [3, 4],
    );

void main() {
  test('pair request and response round-trip', () {
    final request =
        SignalMessage.decode(PairRequest(_payload('A')).encode()) as PairRequest;
    expect(request.payload.deviceId, equals('A'));

    final response = SignalMessage.decode(PairResponse(_payload('B')).encode())
        as PairResponse;
    expect(response.payload.name, equals('dev-B'));
  });

  test('beacon wire format carries identity and port', () {
    final json = {..._payload('A').toJson(), 'port': 9000};
    expect(PairingPayload.fromJson(json).deviceId, equals('A'));
    expect(json['port'], equals(9000));
  });

  test('pairing code is symmetric, stable and six digits', () async {
    final code = await pairingCode('AAA', 'BBB');
    expect(code, equals(await pairingCode('BBB', 'AAA')));
    expect(code, equals(await pairingCode('AAA', 'BBB')));
    expect(code.length, equals(6));
  });

  test('mutual handshake exchanges payloads over a socket channel', () async {
    final server = LanSignalingServer(0);
    await server.start();

    PairingPayload? serverReceived;
    server.connections.listen((channel) async {
      final request = await channel.incoming
          .firstWhere((message) => message is PairRequest) as PairRequest;
      serverReceived = request.payload;
      await channel.send(PairResponse(_payload('B')));
    });

    final client =
        await connectLanSignaling(InternetAddress.loopbackIPv4, server.boundPort);
    await client.send(PairRequest(_payload('A')));
    final response = await client.incoming
        .firstWhere((message) => message is PairResponse)
        .timeout(const Duration(seconds: 5)) as PairResponse;

    expect(response.payload.deviceId, equals('B'));
    for (var i = 0; i < 100 && serverReceived == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(serverReceived?.deviceId, equals('A'));

    await client.close();
    await server.stop();
  });
}
