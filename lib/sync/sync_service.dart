import 'dart:async';
import 'dart:io';

import '../core/config.dart';
import '../core/identity.dart';
import '../core/models.dart';
import '../core/pairing.dart';
import '../crypto/aead.dart';
import '../crypto/folder_key.dart';
import '../storage/file_store.dart';
import '../transport/dht.dart';
import '../transport/lan_beacon.dart';
import '../transport/lan_signaling.dart';
import '../transport/negotiator.dart';
import '../transport/signaling.dart';
import 'engine.dart';
import 'index.dart';

class FolderRuntime {
  FolderRuntime({
    required this.config,
    required this.index,
    required this.store,
    required this.infohash,
  });

  final FolderConfig config;
  final FolderIndex index;
  final FileStore store;
  final String infohash;
}

class SyncService {
  SyncService({
    required this.identity,
    required this.config,
    required this.peers,
    required this.folders,
  });

  final DeviceIdentity identity;
  final AppConfig config;
  final List<PairingPayload> peers;
  final List<FolderRuntime> folders;

  final _dhts = <DhtDiscovery>[];
  final _subscriptions = <StreamSubscription<dynamic>>[];
  final _active = <String>{};

  late final LanSignalingServer _signaling;
  LanBeacon? _beacon;

  Future<void> start() async {
    _signaling = LanSignalingServer(0);
    await _signaling.start();
    _subscriptions.add(_signaling.connections.listen(_accept));

    if (config.lanDiscovery) {
      final beacon =
          LanBeacon(deviceId: identity.id, servicePort: _signaling.boundPort);
      await beacon.start();
      _subscriptions.add(beacon.peers.listen(_onLanPeer));
      _beacon = beacon;
    }
    if (config.dhtDiscovery) {
      for (final folder in folders) {
        final dht = DhtDiscovery(
            infohash: folder.infohash, servicePort: _signaling.boundPort);
        await dht.start();
        _subscriptions.add(
            dht.peers.listen((peer) => _dial(peer.address, peer.port, folder)));
        _dhts.add(dht);
      }
    }
  }

  void _onLanPeer(LanPeer peer) {
    if (_peerById(peer.deviceId) == null) return;
    if (identity.id.compareTo(peer.deviceId) >= 0) return;
    for (final folder in folders) {
      if (folder.config.peerIds.contains(peer.deviceId)) {
        _dial(peer.address, peer.port, folder);
      }
    }
  }

  Future<void> _dial(
      InternetAddress address, int port, FolderRuntime folder) async {
    try {
      await _handshake(await connectLanSignaling(address, port), folder);
    } on Object {
      return;
    }
  }

  Future<void> _accept(SignalChannel channel) async {
    try {
      await _handshake(channel, null);
    } on Object {
      await channel.close();
    }
  }

  Future<void> _handshake(SignalChannel channel, FolderRuntime? dialed) async {
    if (dialed != null) {
      await channel.send(SignalHello(dialed.infohash, identity.id));
    }
    final hello = await channel.incoming
        .firstWhere((message) => message is SignalHello)
        .timeout(const Duration(seconds: 10)) as SignalHello;

    final folder = dialed ?? _folderByInfohash(hello.infohash);
    final peer = _peerById(hello.deviceId);
    final allowed = folder != null &&
        hello.infohash == folder.infohash &&
        peer != null &&
        folder.config.peerIds.contains(peer.deviceId);
    final key = peer == null || folder == null
        ? null
        : '${peer.deviceId}/${folder.config.id}';
    if (!allowed || key == null || _active.contains(key)) {
      await channel.close();
      return;
    }
    if (dialed == null) {
      await channel.send(SignalHello(folder.infohash, identity.id));
    }
    _active.add(key);
    try {
      await _run(channel, folder, peer);
    } finally {
      _active.remove(key);
    }
  }

  Future<void> _run(
      SignalChannel channel, FolderRuntime folder, PairingPayload peer) async {
    final link = await negotiate(
      peerId: peer.deviceId,
      channel: channel,
      initiator: identity.id.compareTo(peer.deviceId) < 0,
      iceServers: config.iceServers,
    );
    final cipher = FolderCipher(await deriveFolderKey(
      agreementKeyPair: identity.agreement,
      peerPublicKey: peer.agreementPublicKey(),
      swarmSecret: folder.config.swarmSecret,
    ));
    await SyncEngine(index: folder.index, store: folder.store, cipher: cipher)
        .sync(link);
  }

  PairingPayload? _peerById(String deviceId) {
    for (final peer in peers) {
      if (peer.deviceId == deviceId) return peer;
    }
    return null;
  }

  FolderRuntime? _folderByInfohash(String infohash) {
    for (final folder in folders) {
      if (folder.infohash == infohash) return folder;
    }
    return null;
  }

  Future<void> stop() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _beacon?.stop();
    for (final dht in _dhts) {
      await dht.stop();
    }
    await _signaling.stop();
  }
}
