import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../core/config.dart';
import '../core/folder_share.dart';
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
import '../transport/pairing_code.dart';
import '../transport/signaling.dart';
import '../transport/swarm.dart';
import 'engine.dart';
import 'index.dart';
import 'sync_event.dart';

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
    required this.deviceName,
    required this.config,
    required this.peers,
    required this.folders,
    required this.onIncomingPair,
    required this.onPaired,
    required this.onIncomingShare,
    this.onEvent,
  });

  final DeviceIdentity identity;
  final String deviceName;
  final AppConfig config;
  final List<PairingPayload> peers;
  final List<FolderRuntime> folders;
  final Future<bool> Function(PairingPayload requester, String code) onIncomingPair;
  final void Function(PairingPayload peer) onPaired;
  final Future<bool> Function(FolderShare share, String fromDeviceId) onIncomingShare;
  final void Function(SyncEvent event)? onEvent;

  final _dhts = <DhtDiscovery>[];
  final _subscriptions = <StreamSubscription<dynamic>>[];
  final _active = <String>{};

  late final PairingPayload _self = PairingPayload.ofDevice(identity, deviceName);
  late final LanSignalingServer _signaling;
  LanBeacon? _beacon;

  Stream<LanPeer> get nearby => _beacon?.peers ?? const Stream.empty();

  Future<void> start() async {
    _signaling = LanSignalingServer(0);
    await _signaling.start();
    _subscriptions.add(_signaling.connections.listen(_accept));

    if (config.lanDiscovery) {
      final beacon =
          LanBeacon(payload: _self, servicePort: _signaling.boundPort);
      await beacon.start();
      _subscriptions.add(beacon.peers.listen(_onLanPeer));
      _beacon = beacon;
    }
    if (config.dhtDiscovery) {
      await _announcePairing();
      for (final folder in folders) {
        try {
          final dht = DhtDiscovery(
              infohash: folder.infohash, servicePort: _signaling.boundPort);
          await dht.start();
          _subscriptions.add(
              dht.peers.listen((peer) => _dial(peer.address, peer.port, folder)));
          _dhts.add(dht);
        } on Object {
          continue;
        }
      }
    }
  }

  Future<void> _announcePairing() async {
    try {
      final infohash =
          await infohashFor(utf8.encode('point-machine/pair/${identity.id}'));
      final beacon =
          DhtDiscovery(infohash: infohash, servicePort: _signaling.boundPort);
      await beacon.start();
      _dhts.add(beacon);
    } on Object {
      return;
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

  Future<bool> pairAt(InternetAddress address, int port) async {
    final channel = await connectLanSignaling(address, port);
    try {
      await channel.send(PairRequest(_self));
      final response = await channel.incoming
          .firstWhere((message) => message is PairResponse)
          .timeout(const Duration(seconds: 15)) as PairResponse;
      onPaired(response.payload);
      return true;
    } on Object {
      return false;
    } finally {
      await channel.close();
    }
  }

  Future<bool> pairViaCode(String code) async {
    final infohash = await infohashFor(utf8.encode('point-machine/pair/$code'));
    final dht =
        DhtDiscovery(infohash: infohash, servicePort: _signaling.boundPort);
    await dht.start();
    try {
      final peer = await dht.peers.first.timeout(const Duration(seconds: 45));
      return await pairAt(peer.address, peer.port);
    } on Object {
      return false;
    } finally {
      await dht.stop();
    }
  }

  Future<void> _dial(
      InternetAddress address, int port, FolderRuntime folder) async {
    try {
      final channel = await connectLanSignaling(address, port);
      await channel.send(SignalHello(folder.infohash, identity.id));
      final hello = await channel.incoming
          .firstWhere((message) => message is SignalHello)
          .timeout(const Duration(seconds: 10)) as SignalHello;
      await _establish(channel, folder, hello);
    } on Object {
      return;
    }
  }

  Future<void> _accept(SignalChannel channel) async {
    try {
      final first = await channel.incoming
          .firstWhere((m) =>
              m is SignalHello || m is PairRequest || m is ShareRequest)
          .timeout(const Duration(seconds: 10));
      if (first is PairRequest) {
        await _handlePair(channel, first);
        return;
      }
      if (first is ShareRequest) {
        await _handleShare(channel, first);
        return;
      }
      final hello = first as SignalHello;
      final folder = _folderByInfohash(hello.infohash);
      if (folder == null) {
        await channel.close();
        return;
      }
      await channel.send(SignalHello(folder.infohash, identity.id));
      await _establish(channel, folder, hello);
    } on Object {
      await channel.close();
    }
  }

  Future<bool> shareFolder(
      FolderShare share, PairingPayload peer, InternetAddress address, int port) async {
    final channel = await connectLanSignaling(address, port);
    try {
      await channel.send(ShareRequest(share, identity.id));
      final response = await channel.incoming
          .firstWhere((message) => message is ShareResponse)
          .timeout(const Duration(seconds: 30)) as ShareResponse;
      return response.accepted;
    } on Object {
      return false;
    } finally {
      await channel.close();
    }
  }

  Future<void> _handleShare(SignalChannel channel, ShareRequest request) async {
    try {
      if (_peerById(request.deviceId) == null) return;
      final accepted = await onIncomingShare(request.share, request.deviceId);
      await channel.send(ShareResponse(accepted));
    } finally {
      await channel.close();
    }
  }

  Future<void> _handlePair(SignalChannel channel, PairRequest request) async {
    try {
      final code = await pairingCode(identity.id, request.payload.deviceId);
      if (await onIncomingPair(request.payload, code)) {
        await channel.send(PairResponse(_self));
        onPaired(request.payload);
      }
    } finally {
      await channel.close();
    }
  }

  Future<void> _establish(
      SignalChannel channel, FolderRuntime folder, SignalHello hello) async {
    final peer = _peerById(hello.deviceId);
    final allowed = hello.infohash == folder.infohash &&
        peer != null &&
        folder.config.peerIds.contains(peer.deviceId);
    final key = peer == null ? null : '${peer.deviceId}/${folder.config.id}';
    if (!allowed || key == null || _active.contains(key)) {
      await channel.close();
      return;
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
    final context = (peerId: peer.deviceId, folderId: folder.config.id);
    onEvent?.call(SyncEvent(SyncEventKind.connected,
        peerId: context.peerId, folderId: context.folderId));
    try {
      await SyncEngine(
        index: folder.index,
        store: folder.store,
        cipher: cipher,
        onEvent: (event) => onEvent?.call(
            event.withContext(peerId: context.peerId, folderId: context.folderId)),
      ).sync(link);
    } finally {
      onEvent?.call(SyncEvent(SyncEventKind.disconnected,
          peerId: context.peerId, folderId: context.folderId));
    }
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
