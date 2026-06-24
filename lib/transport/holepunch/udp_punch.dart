import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import '../nat/port_mapper.dart';
import '../nat/port_mapping.dart';
import '../signaling.dart';
import 'candidates.dart';

const _probe = 0x10;
const _pong = 0x11;
const _done = 0x12;

final _random = Random.secure();

class PunchResult {
  PunchResult({required this.socket, required this.remote, required this.mapper});

  final RawDatagramSocket socket;
  final PunchCandidate remote;
  final PortMapper? mapper;
}

Future<PunchResult?> holePunch({
  required SignalChannel channel,
  required bool initiator,
  required String token,
  bool mapPort = true,
}) async {
  final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  PortMapper? mapper;
  PunchCandidate? mapped;
  if (mapPort) {
    mapper = PortMapper(internalPort: socket.port, protocol: MapProtocol.udp);
    final mapping = await mapper.start();
    final external = mapping?.externalAddress;
    if (external != null) {
      mapped = PunchCandidate(external, mapping!.externalPort);
    } else {
      await mapper.dispose();
      mapper = null;
    }
  }

  try {
    final local = await localCandidates(socket.port, mapped: mapped);
    final remote = await _exchange(channel, token, initiator, local);
    final winner = await _connect(socket, remote);
    if (winner == null) throw const _PunchFailed();
    return PunchResult(socket: socket, remote: winner, mapper: mapper);
  } on Object {
    await mapper?.dispose();
    socket.close();
    return null;
  }
}

Future<List<PunchCandidate>> _exchange(
  SignalChannel channel,
  String token,
  bool initiator,
  List<PunchCandidate> local,
) async {
  final encoded = [for (final candidate in local) candidate.encode()];
  const timeout = Duration(seconds: 15);
  if (initiator) {
    final answer = channel.incoming
        .firstWhere((m) => m is PunchAnswer && m.token == token)
        .timeout(timeout);
    await channel.send(PunchOffer(token, encoded));
    return _parse((await answer as PunchAnswer).candidates);
  }
  final offer = channel.incoming
      .firstWhere((m) => m is PunchOffer && m.token == token)
      .timeout(timeout);
  final received = (await offer as PunchOffer).candidates;
  await channel.send(PunchAnswer(token, encoded));
  return _parse(received);
}

List<PunchCandidate> _parse(List<String> encoded) => [
  for (final value in encoded) ?PunchCandidate.decode(value),
];

Future<PunchCandidate?> _connect(
  RawDatagramSocket socket,
  List<PunchCandidate> remote,
) async {
  if (remote.isEmpty) return null;
  final nonce = _nonce();
  final completer = Completer<PunchCandidate?>();
  PunchCandidate? confirmed;
  var remoteDone = false;

  void maybeFinish() {
    if (confirmed != null && remoteDone && !completer.isCompleted) {
      completer.complete(confirmed);
    }
  }

  final subscription = socket.listen((event) {
    if (event != RawSocketEvent.read) return;
    final datagram = socket.receive();
    if (datagram == null || datagram.data.isEmpty) return;
    final source = PunchCandidate(datagram.address, datagram.port);
    switch (datagram.data[0]) {
      case _probe:
        if (datagram.data.length >= 5) {
          socket.send(
            _frame(_pong, datagram.data.sublist(1, 5)),
            datagram.address,
            datagram.port,
          );
        }
      case _pong:
        if (confirmed == null && _matches(datagram.data, nonce)) {
          confirmed = source;
        }
        maybeFinish();
      case _done:
        if (confirmed == source) remoteDone = true;
        maybeFinish();
    }
  });

  final probe = _frame(_probe, nonce);
  void beat() {
    final target = confirmed;
    if (target == null) {
      for (final candidate in remote) {
        socket.send(probe, candidate.address, candidate.port);
      }
    } else {
      socket.send(_frame(_done, nonce), target.address, target.port);
    }
  }

  beat();
  final timer = Timer.periodic(const Duration(milliseconds: 200), (_) => beat());
  try {
    return await completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () => null,
    );
  } finally {
    timer.cancel();
    await subscription.cancel();
  }
}

Uint8List _nonce() =>
    Uint8List.fromList(List.generate(4, (_) => _random.nextInt(256)));

Uint8List _frame(int type, List<int> nonce) =>
    Uint8List.fromList([type, ...nonce]);

bool _matches(Uint8List data, Uint8List nonce) {
  if (data.length < 5) return false;
  for (var i = 0; i < 4; i++) {
    if (data[i + 1] != nonce[i]) return false;
  }
  return true;
}

class _PunchFailed implements Exception {
  const _PunchFailed();
}
