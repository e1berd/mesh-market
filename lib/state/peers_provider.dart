import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../core/pairing.dart';
import '../core/paths.dart';

final pairedPeersProvider =
    AsyncNotifierProvider<PairedPeersNotifier, List<PairingPayload>>(
        PairedPeersNotifier.new);

class PairedPeersNotifier extends AsyncNotifier<List<PairingPayload>> {
  late File _file;

  @override
  Future<List<PairingPayload>> build() async {
    _file = File(p.join((await appDataDir()).path, 'peers.json'));
    if (!await _file.exists()) return const [];
    final list = jsonDecode(await _file.readAsString()) as List;
    return [
      for (final item in list)
        PairingPayload.fromJson((item as Map).cast<String, Object?>()),
    ];
  }

  Future<void> add(PairingPayload peer) async {
    final peers = [...?state.value]
      ..removeWhere((existing) => existing.deviceId == peer.deviceId);
    await _persist([...peers, peer]);
  }

  Future<void> remove(String deviceId) async =>
      _persist([...?state.value]..removeWhere((p) => p.deviceId == deviceId));

  Future<void> _persist(List<PairingPayload> peers) async {
    await _file.writeAsString(jsonEncode([for (final p in peers) p.toJson()]));
    state = AsyncData(peers);
  }
}
