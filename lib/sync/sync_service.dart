import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

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
import '../transport/peer_link.dart';
import '../transport/signaling.dart';
import '../transport/swarm.dart';
import 'engine.dart';
import 'index.dart';
import 'scanner.dart';
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
    this.onFolderChanged,
  });

  final DeviceIdentity identity;
  final String deviceName;
  final AppConfig config;
  List<PairingPayload> peers;
  List<FolderRuntime> folders;
  final Future<bool> Function(PairingPayload requester, String code) onIncomingPair;
  final void Function(PairingPayload peer) onPaired;
  final Future<bool> Function(FolderShare share, String fromDeviceId) onIncomingShare;
  final void Function(SyncEvent event)? onEvent;
  final void Function(String folderId)? onFolderChanged;

  final _dhts = <DhtDiscovery>[];
  final _subscriptions = <StreamSubscription<dynamic>>[];
  final _active = <String>{};
  final _sessions = <({String folderId, SyncEngine engine, PeerLink link})>[];
  final _debounce = <String, Timer>{};
  final _seen = <String, ({InternetAddress address, int port})>{};
  final _shared = <String>{};
  final _activated = <String>{};
  bool _syncActive = false;

  late final PairingPayload _self = PairingPayload.ofDevice(identity, deviceName);
  late final LanSignalingServer _signaling;
  LanBeacon? _beacon;

  static const _signalingPort = 49322;

  Stream<LanPeer> get nearby => _beacon?.peers ?? const Stream.empty();

  void _log(String message) => debugPrint('[pm.sync] $message');

  Future<void> start() async {
    _signaling = LanSignalingServer(_signalingPort);
    try {
      await _signaling.start();
    } on Object {
      _signaling = LanSignalingServer(0);
      await _signaling.start();
    }
    _subscriptions.add(_signaling.connections.listen(_accept));
    _log('start id=${identity.id} port=${_signaling.boundPort} '
        'peers=${peers.length} folders=${folders.length} '
        'grants=${[for (final f in folders) '${f.config.label}:${f.config.peerIds.length}']}');

    if (config.lanDiscovery) {
      try {
        final beacon =
            LanBeacon(payload: _self, servicePort: _signaling.boundPort);
        await beacon.start();
        _subscriptions.add(beacon.peers.listen(_onLanPeer));
        _beacon = beacon;
      } on Object catch (error) {
        _log('beacon failed: $error');
      }
    }
    if (config.dhtDiscovery) await _announcePairing();
    for (final folder in folders) {
      _activateFolder(folder);
    }
  }

  void updatePeers(List<PairingPayload> next) => peers = next;

  void updateFolders(List<FolderRuntime> next) {
    folders = next;
    for (final folder in next) {
      _activateFolder(folder);
    }
  }

  void _activateFolder(FolderRuntime folder) {
    if (!_activated.add(folder.config.id)) return;
    final folderId = folder.config.id;
    unawaited(_rescan(folder));
    _watch(folder);
    if (config.dhtDiscovery) {
      () async {
        try {
          final dht = DhtDiscovery(
              infohash: folder.infohash, servicePort: _signaling.boundPort);
          await dht.start();
          _subscriptions.add(dht.peers.listen((peer) {
            if (!_syncActive) return;
            final current = _folderById(folderId);
            if (current != null) _dial(peer.address, peer.port, current);
          }));
          _dhts.add(dht);
        } on Object {
          return;
        }
      }();
    }
  }

  void _watch(FolderRuntime folder) {
    try {
      _subscriptions.add(
        Directory(folder.config.localPath)
            .watch(recursive: true)
            .listen((_) => _scheduleRescan(folder)),
      );
    } on Object {
      return;
    }
  }

  void _scheduleRescan(FolderRuntime folder) {
    _debounce[folder.config.id]?.cancel();
    _debounce[folder.config.id] =
        Timer(const Duration(milliseconds: 700), () => _rescan(folder));
  }

  Future<void> _rescan(FolderRuntime folder) async {
    await FolderScanner(
      deviceId: identity.id,
      index: folder.index,
      store: folder.store,
    ).scan();
    onFolderChanged?.call(folder.config.id);
    for (final session in _sessions) {
      if (session.folderId == folder.config.id) {
        await session.engine.announce(session.link);
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

  void setSyncActive(bool active) {
    if (_syncActive == active) return;
    _syncActive = active;
    _log('sync active=$active');
    if (active) _dialAllGranted();
  }

  void _dialAllGranted() {
    for (final entry in _seen.entries) {
      final peer = _peerById(entry.key);
      if (peer == null) continue;
      for (final folder in folders) {
        if (folder.config.peerIds.contains(peer.deviceId)) {
          _dial(entry.value.address, entry.value.port, folder);
        }
      }
    }
  }

  void _onLanPeer(LanPeer peer) {
    _seen[peer.deviceId] = (address: peer.address, port: peer.port);
    final known = _peerById(peer.deviceId) != null;
    _log('lan peer ${peer.deviceId} @${peer.address.address}:${peer.port} '
        'known=$known active=$_syncActive');
    if (!known) return;
    unawaited(_pushShares(peer));
    if (!_syncActive) return;
    for (final folder in folders) {
      if (folder.config.peerIds.contains(peer.deviceId)) {
        _dial(peer.address, peer.port, folder);
      }
    }
  }

  Future<void> _pushShares(LanPeer peer) async {
    for (final folder in folders) {
      if (!folder.config.peerIds.contains(peer.deviceId)) continue;
      final key = '${peer.deviceId}/${folder.config.id}';
      if (_shared.contains(key)) continue;
      _log('pushing share "${folder.config.label}" to ${peer.deviceId}');
      final accepted = await shareFolder(
        _shareOf(folder),
        peer.payload,
        peer.address,
        peer.port,
      );
      _log('share "${folder.config.label}" accepted=$accepted');
      if (accepted) _shared.add(key);
    }
  }

  FolderShare _shareOf(FolderRuntime folder) => FolderShare(
        folderId: folder.config.id,
        label: folder.config.label,
        swarmSecret: folder.config.swarmSecret,
      );

  Future<bool> shareFolderWith(FolderShare share, PairingPayload peer) async {
    final seen = _seen[peer.deviceId];
    _log('shareFolderWith ${peer.deviceId} seen=${seen != null}');
    if (seen == null) return false;
    final accepted = await shareFolder(share, peer, seen.address, seen.port);
    if (accepted) _shared.add('${peer.deviceId}/${share.folderId}');
    return accepted;
  }

  Future<bool> pairAt(InternetAddress address, int port) async {
    SignalChannel? channel;
    try {
      channel = await connectLanSignaling(address, port);
      await channel.send(PairRequest(_self));
      final response = await channel.incoming
          .firstWhere((message) => message is PairResponse)
          .timeout(const Duration(seconds: 15)) as PairResponse;
      onPaired(response.payload);
      return true;
    } on Object {
      return false;
    } finally {
      await channel?.close();
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
    _log('dial "${folder.config.label}" -> ${address.address}:$port');
    try {
      final channel = await connectLanSignaling(address, port);
      await channel.send(SignalHello(folder.infohash, identity.id));
      final hello = await channel.incoming
          .firstWhere((message) => message is SignalHello)
          .timeout(const Duration(seconds: 10)) as SignalHello;
      _log('dial got hello from ${hello.deviceId}');
      await _establish(channel, folder, hello);
    } on Object catch (error) {
      _log('dial failed: $error');
      return;
    }
  }

  Future<void> _accept(SignalChannel channel) async {
    try {
      final first = await channel.incoming
          .firstWhere((m) =>
              m is SignalHello || m is PairRequest || m is ShareRequest)
          .timeout(const Duration(seconds: 10));
      _log('incoming signal ${first.runtimeType}');
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
    SignalChannel? channel;
    try {
      channel = await connectLanSignaling(address, port);
      await channel.send(ShareRequest(share, identity.id));
      final response = await channel.incoming
          .firstWhere((message) => message is ShareResponse)
          .timeout(const Duration(seconds: 30)) as ShareResponse;
      return response.accepted;
    } on Object {
      return false;
    } finally {
      await channel?.close();
    }
  }

  Future<void> _handleShare(SignalChannel channel, ShareRequest request) async {
    try {
      final knownPeer = _peerById(request.deviceId) != null;
      final exists = _folderById(request.share.folderId) != null;
      _log('share request "${request.share.label}" from ${request.deviceId} '
          'knownPeer=$knownPeer exists=$exists');
      if (!knownPeer) return;
      final accepted =
          exists ? true : await onIncomingShare(request.share, request.deviceId);
      _log('share request resolved accepted=$accepted');
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
    _log('establish "${folder.config.label}" allowed=$allowed '
        'active=${key != null && _active.contains(key)}');
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
    final initiator = identity.id.compareTo(peer.deviceId) < 0;
    _log('negotiate "${folder.config.label}" initiator=$initiator');
    final link = await negotiate(
      peerId: peer.deviceId,
      channel: channel,
      initiator: initiator,
      iceServers: config.iceServers,
    );
    _log('link open "${folder.config.label}" <-> ${peer.deviceId}');
    final cipher = FolderCipher(await deriveFolderKey(
      agreementKeyPair: identity.agreement,
      peerPublicKey: peer.agreementPublicKey(),
      swarmSecret: folder.config.swarmSecret,
    ));
    final context = (peerId: peer.deviceId, folderId: folder.config.id);
    final engine = SyncEngine(
      index: folder.index,
      store: folder.store,
      cipher: cipher,
      onEvent: (event) => onEvent?.call(
          event.withContext(peerId: context.peerId, folderId: context.folderId)),
    );
    final session = (folderId: folder.config.id, engine: engine, link: link);
    _sessions.add(session);
    onEvent?.call(SyncEvent(SyncEventKind.connected,
        peerId: context.peerId, folderId: context.folderId));
    _log('sync started "${folder.config.label}"');
    try {
      await engine.sync(link);
      _log('sync finished "${folder.config.label}"');
    } finally {
      _sessions.remove(session);
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

  FolderRuntime? _folderById(String folderId) {
    for (final folder in folders) {
      if (folder.config.id == folderId) return folder;
    }
    return null;
  }

  Future<void> stop() async {
    for (final timer in _debounce.values) {
      timer.cancel();
    }
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
