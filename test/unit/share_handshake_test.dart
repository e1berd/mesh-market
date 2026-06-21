import 'dart:io';

import 'package:point_machine/core/folder_share.dart';
import 'package:point_machine/transport/lan_signaling.dart';
import 'package:point_machine/transport/signaling.dart';
import 'package:test/test.dart';

void main() {
  test('share request and response round-trip', () {
    final request = SignalMessage.decode(
      const ShareRequest(
        FolderShare(folderId: 'f', label: 'Docs', swarmSecret: [1, 2]),
        'A',
      ).encode(),
    ) as ShareRequest;
    expect(request.share.folderId, equals('f'));
    expect(request.deviceId, equals('A'));

    final response =
        SignalMessage.decode(const ShareResponse(true).encode()) as ShareResponse;
    expect(response.accepted, isTrue);
  });

  test('share handshake delivers the folder and returns the decision', () async {
    final server = LanSignalingServer(0);
    await server.start();

    FolderShare? received;
    server.connections.listen((channel) async {
      final request = await channel.incoming
          .firstWhere((message) => message is ShareRequest) as ShareRequest;
      received = request.share;
      await channel.send(const ShareResponse(true));
    });

    final client =
        await connectLanSignaling(InternetAddress.loopbackIPv4, server.boundPort);
    await client.send(const ShareRequest(
      FolderShare(folderId: 'f1', label: 'L', swarmSecret: [9]),
      'A',
    ));
    final response = await client.incoming
        .firstWhere((message) => message is ShareResponse)
        .timeout(const Duration(seconds: 5)) as ShareResponse;

    expect(response.accepted, isTrue);
    for (var i = 0; i < 100 && received == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(received?.folderId, equals('f1'));

    await client.close();
    await server.stop();
  });
}
