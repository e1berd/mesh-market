import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/config.dart';
import '../core/folder_share.dart';
import '../core/identity.dart';
import '../core/models.dart';
import '../core/pairing.dart';
import '../crypto/aead.dart';
import '../crypto/folder_key.dart';
import '../storage/file_store.dart';
import '../transport/bluetooth_transport.dart';
import '../transport/dht.dart';
import '../transport/holepunch/kcp_link.dart';
import '../transport/holepunch/udp_punch.dart';
import '../transport/ip_link_bringup.dart';
import '../transport/lan_beacon.dart';
import '../transport/lan_signaling.dart';
import '../transport/multipeer_transport.dart';
import '../transport/nat/port_mapper.dart';
import '../transport/nat/port_mapping.dart';
import '../transport/negotiator.dart';
import '../transport/pairing_code.dart';
import '../transport/peer_link.dart';
import '../transport/relay_transport.dart';
import '../transport/signaling.dart';
import '../transport/sync_transport.dart';
import '../transport/swarm.dart';
import '../transport/tcp_transport.dart';
import '../transport/wifi_aware_transport.dart';
import '../transport/wifi_direct_transport.dart';
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
    this.onProgress,
  });

  final DeviceIdentity identity;
  final String deviceName;
  final AppConfig config;
  List<PairingPayload> peers;
  List<FolderRuntime> folders;
  final Future<bool> Function(PairingPayload requester, String code)
  onIncomingPair;
  final void Function(PairingPayload peer) onPaired;
  final Future<bool> Function(FolderShare share, String fromDeviceId)
  onIncomingShare;
  final void Function(SyncEvent event)? onEvent;
  final void Function(String folderId)? onFolderChanged;
  final void Function(SyncProgress progress)? onProgress;

  final _dhts = <DhtDiscovery>[];
  final _subscriptions = <StreamSubscription<dynamic>>[];
  final _active = <String>{};
  final _sessions = <({String folderId, SyncEngine engine, PeerLink link})>[];
  final _debounce = <String, Timer>{};
  final _seen =
      <String, ({InternetAddress address, int port, int? syncPort})>{};
  final _endpoints = <String, ({InternetAddress address, int port})>{};
  final _random = Random.secure();
  final _shared = <String>{};
  final _activated = <String>{};
  final _lastSynced = <String, DateTime>{};
  final _transportCoordinator = SyncTransportCoordinator();
  late final DirectTcpTransport _tcp = DirectTcpTransport(
    deviceId: identity.id,
  );
  late final IpLinkBringup _bringup = IpLinkBringup(_tcp);
  late final BluetoothTransport _bluetooth = BluetoothTransport(
    deviceId: identity.id,
    deviceName: deviceName,
  );
  late final WifiDirectTransport _wifiDirect = WifiDirectTransport(
    deviceId: identity.id,
    deviceName: deviceName,
    bringup: _bringup,
    syncPort: () => _tcp.boundPort,
  );
  late final WifiAwareTransport _wifiAware = WifiAwareTransport(
    deviceId: identity.id,
    bringup: _bringup,
    syncPort: () => _tcp.boundPort,
  );
  late final MultipeerTransport _multipeer = MultipeerTransport(
    deviceId: identity.id,
  );
  bool _wifiDirectSupported = false;
  bool _wifiAwareSupported = false;
  bool _multipeerSupported = false;
  Timer? _offlineTimer;
  Timer? _relayTimer;
  bool _syncActive = false;

  late final PairingPayload _self = PairingPayload.ofDevice(
    identity,
    deviceName,
  );
  late LanSignalingServer _signaling;
  LanBeacon? _beacon;
  PortMapper? _signalMap;
  PortMapper? _dataMap;
  int? _externalSignalPort;
  PortMapping? _externalData;

  static const _signalingPort = 49322;

  int get _announcePort => _externalSignalPort ?? _signaling.boundPort;

  SignalHello _hello(FolderRuntime folder) => SignalHello(
    folder.infohash,
    identity.id,
    syncPort: _externalData?.externalPort,
    syncAddress: _externalData?.externalAddress?.address,
  );

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
    try {
      await _tcp.start();
      _subscriptions.add(_tcp.incoming.listen(_acceptTcp));
    } on Object catch (error) {
      _log('tcp failed: $error');
    }
    _log(
      'start id=${identity.id} port=${_signaling.boundPort} '
      'peers=${peers.length} folders=${folders.length} '
      'grants=${[for (final f in folders) '${f.config.label}:${f.config.peerIds.length}']}',
    );

    if (config.lanDiscovery) {
      try {
        final beacon = LanBeacon(
          payload: _self,
          servicePort: _signaling.boundPort,
          syncPort: _tcp.boundPort == 0 ? null : _tcp.boundPort,
        );
        await beacon.start();
        _subscriptions.add(beacon.peers.listen(_onLanPeer));
        _beacon = beacon;
      } on Object catch (error) {
        _log('beacon failed: $error');
      }
    }
    if (config.portMapping) unawaited(_startPortMapping());
    if (config.dhtDiscovery) unawaited(_announcePairing());
    if (config.bluetoothDiscovery) unawaited(_startBluetooth());
    unawaited(_startOfflineTransports());
    _startOfflineDialing();
    _startRelayDialing();
    for (final folder in folders) {
      _activateFolder(folder);
    }
  }

  Future<void> _startBluetooth() async {
    try {
      await _bluetooth.start();
      _subscriptions.add(_bluetooth.incoming.listen(_acceptBluetooth));
    } on Object catch (error) {
      _log('bluetooth failed: $error');
    }
  }

  Future<void> _startPortMapping() async {
    try {
      final signalPort = _signaling.boundPort;
      if (signalPort != 0) {
        final mapper = PortMapper(internalPort: signalPort);
        _signalMap = mapper;
        final mapping = await mapper.start();
        _externalSignalPort = mapping?.externalPort;
        if (mapping != null) _log('mapped signaling $mapping');
      }
      final dataPort = _tcp.boundPort;
      if (dataPort != 0) {
        final mapper = PortMapper(internalPort: dataPort);
        _dataMap = mapper;
        _externalData = await mapper.start();
        if (_externalData != null) _log('mapped data $_externalData');
      }
    } on Object catch (error) {
      _log('port mapping failed: $error');
    }
  }

  Future<void> _startOfflineTransports() async {
    try {
      _wifiDirectSupported = await WifiDirectTransport.isSupported();
      _wifiAwareSupported = await WifiAwareTransport.isSupported();
      _multipeerSupported = await MultipeerTransport.isSupported();
    } on Object catch (error) {
      _log('offline transport probe failed: $error');
      return;
    }
    if (config.wifiDirectDiscovery && _wifiDirectSupported) {
      try {
        await _wifiDirect.start();
      } on Object catch (error) {
        _log('wifiDirect failed: $error');
      }
    }
    if (config.wifiAwareDiscovery && _wifiAwareSupported) {
      try {
        await _wifiAware.start();
      } on Object catch (error) {
        _log('wifiAware failed: $error');
      }
    }
    if (config.multipeerDiscovery && _multipeerSupported) {
      try {
        await _multipeer.start();
        _subscriptions.add(_multipeer.incoming.listen(_acceptMultipeer));
      } on Object catch (error) {
        _log('multipeer failed: $error');
      }
    }
  }

  bool get _offlineEnabled =>
      config.bluetoothDiscovery ||
      (config.wifiDirectDiscovery && _wifiDirectSupported) ||
      (config.multipeerDiscovery && _multipeerSupported) ||
      (config.wifiAwareDiscovery && _wifiAwareSupported);

  void _startOfflineDialing() {
    _offlineTimer?.cancel();
    if (!_offlineEnabled) return;
    _offlineTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_syncActive) unawaited(_dialOfflineAllGranted());
    });
  }

  Future<void> _dialOfflineAllGranted() async {
    for (final peer in peers) {
      for (final folder in folders) {
        if (folder.config.peerIds.contains(peer.deviceId) &&
            _canStart(peer.deviceId, folder.config.id)) {
          await _dialOffline(peer, folder);
        }
      }
    }
  }

  Future<void> _dialOffline(PairingPayload peer, FolderRuntime folder) async {
    final key = '${peer.deviceId}/${folder.config.id}';
    if (_active.contains(key)) return;
    _active.add(key);
    try {
      final target = SyncTransportTarget(
        peerId: peer.deviceId,
        folderId: folder.config.id,
        folderLabel: folder.config.label,
      );
      final result = await _transportCoordinator.open(
        target,
        _offlineCandidates(folder: folder, peer: peer),
      );
      await _runLink(
        folder: folder,
        peer: peer,
        link: result.link,
        transport: result.kind.id,
        transportLabel: result.kind.label,
      );
    } on Object catch (error) {
      _log('offline dial "${folder.config.label}" failed: $error');
    } finally {
      _active.remove(key);
    }
  }

  void _startRelayDialing() {
    _relayTimer?.cancel();
    if (!config.peerRelay) return;
    _relayTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (_syncActive) unawaited(_dialRelayAllGranted());
    });
  }

  Future<void> _dialRelayAllGranted() async {
    for (final folder in folders) {
      for (final peerId in folder.config.peerIds) {
        if (peerId == identity.id) continue;
        final peer = _peerById(peerId);
        if (peer == null || !_canStart(peerId, folder.config.id)) continue;
        await _dialRelay(folder, peer);
      }
    }
  }

  Future<void> _dialRelay(FolderRuntime folder, PairingPayload peer) async {
    final key = _syncKey(peer.deviceId, folder.config.id);
    if (!_active.add(key)) return;
    try {
      final link = await _openRelay(folder, peer.deviceId);
      if (link == null) return;
      await _runLink(
        folder: folder,
        peer: peer,
        link: link,
        transport: SyncTransportKind.relay.id,
        transportLabel: SyncTransportKind.relay.label,
      );
    } on Object catch (error) {
      _log('relay dial "${folder.config.label}" failed: $error');
    } finally {
      _active.remove(key);
    }
  }

  Future<PeerLink?> _openRelay(FolderRuntime folder, String targetId) async {
    for (final relayId in _relayCandidates(folder, targetId)) {
      final endpoint = _signalEndpoint(relayId);
      if (endpoint == null) continue;
      SignalChannel? channel;
      try {
        channel = await connectLanSignaling(endpoint.address, endpoint.port);
        final token = _relayToken();
        final reply = channel.incoming
            .firstWhere((message) {
              if (message is RelayReady) return message.token == token;
              if (message is RelayFail) return message.token == token;
              return false;
            })
            .timeout(const Duration(seconds: 15));
        await channel.send(
          RelayOpen(token, identity.id, targetId, folder.infohash),
        );
        if (await reply is RelayReady) {
          _log('relay "${folder.config.label}" -> $targetId via $relayId');
          return RelayPeerLink(
            peerId: targetId,
            channel: channel,
            token: token,
          );
        }
        await channel.close();
      } on Object {
        await channel?.close();
      }
    }
    return null;
  }

  Iterable<String> _relayCandidates(
    FolderRuntime folder,
    String targetId,
  ) sync* {
    for (final relayId in folder.config.peerIds) {
      if (relayId == identity.id || relayId == targetId) continue;
      if (_peerById(relayId) == null) continue;
      if (_signalEndpoint(relayId) == null) continue;
      yield relayId;
    }
  }

  ({InternetAddress address, int port})? _signalEndpoint(String deviceId) {
    final lan = _seen[deviceId];
    if (lan != null) return (address: lan.address, port: lan.port);
    return _endpoints[deviceId];
  }

  String _relayToken() =>
      base64Url.encode(List.generate(16, (_) => _random.nextInt(256)));

  void updatePeers(List<PairingPayload> next) {
    peers = next;
    if (_syncActive) _dialAllGranted();
  }

  void updateFolders(List<FolderRuntime> next) {
    folders = next;
    for (final folder in next) {
      _activateFolder(folder);
    }
    if (_syncActive) _dialAllGranted();
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
            infohash: folder.infohash,
            servicePort: _announcePort,
          );
          await dht.start();
          _subscriptions.add(
            dht.peers.listen((peer) {
              if (!_syncActive) return;
              final current = _folderById(folderId);
              if (current != null) {
                _dial(peer.address, peer.port, current, syncPort: null);
              }
            }),
          );
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
        Directory(
          folder.config.localPath,
        ).watch(recursive: true).listen((_) => _scheduleRescan(folder)),
      );
    } on Object {
      return;
    }
  }

  void _scheduleRescan(FolderRuntime folder) {
    _debounce[folder.config.id]?.cancel();
    _lastSynced.removeWhere((key, _) => key.endsWith('/${folder.config.id}'));
    _debounce[folder.config.id] = Timer(
      const Duration(milliseconds: 700),
      () => _rescan(folder),
    );
  }

  Future<void> rescanFolder(String folderId) async {
    final folder = _folderById(folderId);
    if (folder != null) await _rescan(folder);
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
      final infohash = await infohashFor(
        utf8.encode('mesh-market/pair/${identity.id}'),
      );
      final beacon = DhtDiscovery(
        infohash: infohash,
        servicePort: _announcePort,
      );
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
    if (active) {
      _dialAllGranted();
      if (_offlineEnabled) unawaited(_dialOfflineAllGranted());
      if (config.peerRelay) unawaited(_dialRelayAllGranted());
    }
  }

  void _dialAllGranted() {
    for (final entry in _seen.entries) {
      final peer = _peerById(entry.key);
      if (peer == null) continue;
      for (final folder in folders) {
        if (folder.config.peerIds.contains(peer.deviceId) &&
            _canStart(peer.deviceId, folder.config.id)) {
          _dial(
            entry.value.address,
            entry.value.port,
            folder,
            syncPort: entry.value.syncPort,
          );
        }
      }
    }
  }

  void _onLanPeer(LanPeer peer) {
    _seen[peer.deviceId] = (
      address: peer.address,
      port: peer.port,
      syncPort: peer.syncPort,
    );
    final existing = _peerById(peer.deviceId);
    final known = existing != null;
    _log(
      'lan peer ${peer.deviceId} @${peer.address.address}:${peer.port} '
      'known=$known active=$_syncActive',
    );
    if (!known) return;
    if (existing.name != peer.payload.name) onPaired(peer.payload);
    unawaited(_pushShares(peer));
    if (!_syncActive) return;
    for (final folder in folders) {
      if (folder.config.peerIds.contains(peer.deviceId) &&
          _canStart(peer.deviceId, folder.config.id)) {
        _dial(peer.address, peer.port, folder, syncPort: peer.syncPort);
      }
    }
  }

  bool _canStart(String peerId, String folderId) {
    final key = _syncKey(peerId, folderId);
    if (_active.contains(key)) return false;
    final last = _lastSynced[key];
    if (last == null) return true;
    return DateTime.now().difference(last) > const Duration(seconds: 30);
  }

  String _syncKey(String peerId, String folderId) {
    final pair = [identity.id, peerId]..sort();
    return '${pair.first}/${pair.last}/$folderId';
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
      final response =
          await channel.incoming
                  .firstWhere((message) => message is PairResponse)
                  .timeout(const Duration(seconds: 15))
              as PairResponse;
      onPaired(response.payload);
      return true;
    } on Object {
      return false;
    } finally {
      await channel?.close();
    }
  }

  Future<bool> pairViaCode(String code) async {
    final nearby = _seen[code];
    if (nearby != null && await pairAt(nearby.address, nearby.port)) {
      return true;
    }

    final infohash = await infohashFor(utf8.encode('mesh-market/pair/$code'));
    final dht = DhtDiscovery(
      infohash: infohash,
      servicePort: _announcePort,
    );
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
    InternetAddress address,
    int port,
    FolderRuntime folder, {
    required int? syncPort,
  }) async {
    _log('dial "${folder.config.label}" -> ${address.address}:$port');
    try {
      final channel = await connectLanSignaling(address, port);
      await channel.send(_hello(folder));
      final hello =
          await channel.incoming
                  .firstWhere((message) => message is SignalHello)
                  .timeout(const Duration(seconds: 10))
              as SignalHello;
      _log('dial got hello from ${hello.deviceId}');
      _endpoints[hello.deviceId] = (address: address, port: port);
      final peerSyncPort = hello.syncPort ?? syncPort;
      final peerSyncAddress = hello.syncAddress != null
          ? InternetAddress.tryParse(hello.syncAddress!) ?? address
          : address;
      await _establish(
        channel,
        folder,
        hello,
        peerSyncAddress,
        port,
        peerSyncPort,
      );
    } on Object catch (error) {
      _log('dial failed: $error');
      return;
    }
  }

  Future<void> _accept(SignalChannel channel) async {
    try {
      final first = await channel.incoming
          .firstWhere(
            (m) =>
                m is SignalHello ||
                m is PairRequest ||
                m is ShareRequest ||
                m is RelayOpen ||
                m is RelayInbound,
          )
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
      if (first is RelayOpen) {
        await _handleRelayOpen(channel, first);
        return;
      }
      if (first is RelayInbound) {
        await _handleRelayInbound(channel, first);
        return;
      }
      final hello = first as SignalHello;
      final folder = _folderByInfohash(hello.infohash);
      if (folder == null) {
        await channel.close();
        return;
      }
      await channel.send(_hello(folder));
      if (!_canStart(hello.deviceId, folder.config.id)) {
        await channel.close();
        return;
      }
      await _establish(channel, folder, hello, null, null, null);
    } on Object {
      await channel.close();
    }
  }

  Future<bool> shareFolder(
    FolderShare share,
    PairingPayload peer,
    InternetAddress address,
    int port,
  ) async {
    SignalChannel? channel;
    try {
      channel = await connectLanSignaling(address, port);
      await channel.send(ShareRequest(share, identity.id));
      final response =
          await channel.incoming
                  .firstWhere((message) => message is ShareResponse)
                  .timeout(const Duration(seconds: 30))
              as ShareResponse;
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
      _log(
        'share request "${request.share.label}" from ${request.deviceId} '
        'knownPeer=$knownPeer exists=$exists',
      );
      if (!knownPeer) return;
      final accepted = exists
          ? true
          : await onIncomingShare(request.share, request.deviceId);
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

  Future<void> _handleRelayOpen(SignalChannel chA, RelayOpen open) async {
    final folder = _folderByInfohash(open.infohash);
    final allowed =
        config.peerRelay &&
        folder != null &&
        _peerById(open.from) != null &&
        _peerById(open.target) != null &&
        folder.config.peerIds.contains(open.from) &&
        folder.config.peerIds.contains(open.target);
    final endpoint = allowed ? _signalEndpoint(open.target) : null;
    if (endpoint == null) {
      await chA.send(RelayFail(open.token));
      await chA.close();
      return;
    }
    SignalChannel? chB;
    try {
      chB = await connectLanSignaling(endpoint.address, endpoint.port);
      final ready = chB.incoming
          .firstWhere((m) => m is RelayReady && m.token == open.token)
          .timeout(const Duration(seconds: 15));
      await chB.send(RelayInbound(open.token, open.from, open.infohash));
      await ready;
      await chA.send(RelayReady(open.token));
      _log('relay bridge ${open.from} <-> ${open.target}');
      await bridgeRelay(open.token, chA, chB);
    } on Object catch (error) {
      _log('relay bridge failed: $error');
      await chA.send(RelayFail(open.token));
      await chA.close();
      await chB?.close();
    }
  }

  Future<void> _handleRelayInbound(
    SignalChannel channel,
    RelayInbound inbound,
  ) async {
    final folder = _folderByInfohash(inbound.infohash);
    final peer = _peerById(inbound.from);
    final allowed =
        config.peerRelay &&
        _syncActive &&
        folder != null &&
        peer != null &&
        folder.config.peerIds.contains(peer.deviceId);
    final key = allowed
        ? _syncKey(peer.deviceId, folder.config.id)
        : null;
    if (key == null || !_active.add(key)) {
      await channel.close();
      return;
    }
    final link = RelayPeerLink(
      peerId: peer!.deviceId,
      channel: channel,
      token: inbound.token,
    );
    await channel.send(RelayReady(inbound.token));
    try {
      await _runLink(
        folder: folder!,
        peer: peer,
        link: link,
        transport: SyncTransportKind.relay.id,
        transportLabel: SyncTransportKind.relay.label,
      );
    } finally {
      _active.remove(key);
    }
  }

  Future<void> _establish(
    SignalChannel channel,
    FolderRuntime folder,
    SignalHello hello,
    InternetAddress? address,
    int? port,
    int? syncPort,
  ) async {
    final peer = _peerById(hello.deviceId);
    final allowed =
        hello.infohash == folder.infohash &&
        peer != null &&
        folder.config.peerIds.contains(peer.deviceId);
    final key = peer == null ? null : _syncKey(peer.deviceId, folder.config.id);
    _log(
      'establish "${folder.config.label}" allowed=$allowed '
      'active=${key != null && _active.contains(key)}',
    );
    if (!allowed || key == null || _active.contains(key)) {
      await channel.close();
      return;
    }
    _active.add(key);
    try {
      await _run(
        channel,
        folder,
        peer,
        address: address,
        port: port,
        syncPort: syncPort,
      );
    } finally {
      _active.remove(key);
    }
  }

  Future<void> _run(
    SignalChannel channel,
    FolderRuntime folder,
    PairingPayload peer, {
    required InternetAddress? address,
    required int? port,
    required int? syncPort,
  }) async {
    final target = SyncTransportTarget(
      peerId: peer.deviceId,
      folderId: folder.config.id,
      folderLabel: folder.config.label,
    );
    String? attemptedTransport;
    final result = await _transportCoordinator
        .open(
          target,
          _transportCandidates(
            channel: channel,
            folder: folder,
            peer: peer,
            address: address,
            port: port,
            syncPort: syncPort,
            onAttempt: (transport) => attemptedTransport = transport,
          ),
        )
        .catchError((Object error) {
          if (attemptedTransport != null) {
            onEvent?.call(
              SyncEvent(
                SyncEventKind.disconnected,
                peerId: peer.deviceId,
                folderId: folder.config.id,
                transport: attemptedTransport,
              ),
            );
          }
          throw error;
        });
    final link = result.link;
    final transport = result.kind.id;
    _log(
      'link open "${folder.config.label}" <-> ${peer.deviceId} via ${result.kind.label}',
    );
    await _runLink(
      folder: folder,
      peer: peer,
      link: link,
      transport: transport,
      transportLabel: result.kind.label,
    );
  }

  Future<void> _runLink({
    required FolderRuntime folder,
    required PairingPayload peer,
    required PeerLink link,
    required String transport,
    required String transportLabel,
  }) async {
    final cipher = FolderCipher(
      await deriveFolderKey(
        agreementKeyPair: identity.agreement,
        peerPublicKey: peer.agreementPublicKey(),
        swarmSecret: folder.config.swarmSecret,
      ),
    );
    final context = (peerId: peer.deviceId, folderId: folder.config.id);
    final peerConfig = folder.config.peer(peer.deviceId);
    final seen = <SyncDirection, ({int done, int total})>{};

    void emitProgress(SyncDirection direction, int done, int total, bool active) {
      seen[direction] = (done: done, total: total);
      onProgress?.call(
        SyncProgress(
          peerId: context.peerId,
          folderId: context.folderId,
          direction: direction,
          done: done,
          total: total,
          active: active,
        ),
      );
    }

    final engine = SyncEngine(
      index: folder.index,
      store: folder.store,
      cipher: cipher,
      canReceive: peerConfig?.canReceive ?? true,
      canSend: peerConfig?.canSend ?? true,
      onEvent: (event) => onEvent?.call(
        event.withContext(
          peerId: context.peerId,
          folderId: context.folderId,
          transport: transport,
        ),
      ),
      onProgress: (done, total) =>
          emitProgress(SyncDirection.incoming, done, total, true),
      onPeerProgress: (done, total) =>
          emitProgress(SyncDirection.outgoing, done, total, true),
    );
    final session = (folderId: folder.config.id, engine: engine, link: link);
    _sessions.add(session);
    onEvent?.call(
      SyncEvent(
        SyncEventKind.connected,
        peerId: context.peerId,
        folderId: context.folderId,
        transport: transport,
      ),
    );
    _log('sync started "${folder.config.label}" via $transportLabel');
    var completed = false;
    try {
      await engine.sync(link);
      completed = true;
      _log('sync finished "${folder.config.label}"');
    } on Object catch (error) {
      _log('sync failed "${folder.config.label}" via $transportLabel: $error');
    } finally {
      _sessions.remove(session);
      await link.close();
      if (completed) {
        _lastSynced[_syncKey(context.peerId, context.folderId)] =
            DateTime.now();
      }
      for (final entry in seen.entries) {
        emitProgress(entry.key, entry.value.done, entry.value.total, false);
      }
      onEvent?.call(
        SyncEvent(
          SyncEventKind.disconnected,
          peerId: context.peerId,
          folderId: context.folderId,
          transport: transport,
        ),
      );
    }
  }

  Future<void> _acceptBluetooth(BluetoothIncomingLink incoming) async {
    final key = '${incoming.peerId}/${incoming.folderId}';
    var activeAdded = false;
    try {
      final folder = _folderById(incoming.folderId);
      final peer = _peerById(incoming.peerId);
      final allowed =
          _syncActive &&
          folder != null &&
          peer != null &&
          folder.config.peerIds.contains(peer.deviceId);
      _log(
        'bluetooth incoming "${folder?.config.label ?? incoming.folderId}" '
        'from ${incoming.peerId} allowed=$allowed active=${_active.contains(key)}',
      );
      if (!allowed || _active.contains(key)) {
        await incoming.link.close();
        return;
      }
      _active.add(key);
      activeAdded = true;
      await _runLink(
        folder: folder,
        peer: peer,
        link: incoming.link,
        transport: SyncTransportKind.bluetooth.id,
        transportLabel: SyncTransportKind.bluetooth.label,
      );
    } on Object catch (error) {
      _log('bluetooth incoming failed: $error');
    } finally {
      if (activeAdded) _active.remove(key);
    }
  }

  Future<void> _acceptMultipeer(MultipeerIncomingLink incoming) async {
    final key = '${incoming.peerId}/${incoming.folderId}';
    var activeAdded = false;
    try {
      final folder = _folderById(incoming.folderId);
      final peer = _peerById(incoming.peerId);
      final allowed =
          _syncActive &&
          folder != null &&
          peer != null &&
          folder.config.peerIds.contains(peer.deviceId);
      _log(
        'multipeer incoming "${folder?.config.label ?? incoming.folderId}" '
        'from ${incoming.peerId} allowed=$allowed active=${_active.contains(key)}',
      );
      if (!allowed || _active.contains(key)) {
        await incoming.link.close();
        return;
      }
      _active.add(key);
      activeAdded = true;
      await _runLink(
        folder: folder,
        peer: peer,
        link: incoming.link,
        transport: SyncTransportKind.multipeer.id,
        transportLabel: SyncTransportKind.multipeer.label,
      );
    } on Object catch (error) {
      _log('multipeer incoming failed: $error');
    } finally {
      if (activeAdded) _active.remove(key);
    }
  }

  Future<void> _acceptTcp(DirectTcpIncomingLink incoming) async {
    final key = '${incoming.peerId}/${incoming.folderId}';
    var activeAdded = false;
    try {
      final folder = _folderById(incoming.folderId);
      final peer = _peerById(incoming.peerId);
      final allowed =
          _syncActive &&
          folder != null &&
          peer != null &&
          folder.config.peerIds.contains(peer.deviceId);
      _log(
        'tcp incoming "${folder?.config.label ?? incoming.folderId}" '
        'from ${incoming.peerId} allowed=$allowed active=${_active.contains(key)}',
      );
      if (!allowed || _active.contains(key)) {
        await incoming.link.close();
        return;
      }
      _active.add(key);
      activeAdded = true;
      await _runLink(
        folder: folder,
        peer: peer,
        link: incoming.link,
        transport: SyncTransportKind.directTcp.id,
        transportLabel: SyncTransportKind.directTcp.label,
      );
    } on Object catch (error) {
      _log('tcp incoming failed: $error');
    } finally {
      if (activeAdded) _active.remove(key);
    }
  }

  Iterable<SyncTransportCandidate> _transportCandidates({
    required SignalChannel channel,
    required FolderRuntime folder,
    required PairingPayload peer,
    required InternetAddress? address,
    required int? port,
    required int? syncPort,
    required void Function(String transport) onAttempt,
  }) sync* {
    yield SyncTransportCandidate(
      descriptor: SyncTransportDescriptor(
        kind: SyncTransportKind.directTcp,
        priority: 5,
        available: address != null && syncPort != null,
      ),
      open: () {
        onAttempt(SyncTransportKind.directTcp.id);
        onEvent?.call(
          SyncEvent(
            SyncEventKind.connecting,
            peerId: peer.deviceId,
            folderId: folder.config.id,
            transport: SyncTransportKind.directTcp.id,
          ),
        );
        return _tcp.open(
          address: address!,
          port: syncPort!,
          peerId: peer.deviceId,
          folderId: folder.config.id,
        );
      },
    );

    yield SyncTransportCandidate(
      descriptor: SyncTransportDescriptor(
        kind: SyncTransportKind.holePunch,
        priority: 8,
        available: config.holePunch,
      ),
      open: () async {
        final initiator = identity.id.compareTo(peer.deviceId) < 0;
        onAttempt(SyncTransportKind.holePunch.id);
        onEvent?.call(
          SyncEvent(
            SyncEventKind.connecting,
            peerId: peer.deviceId,
            folderId: folder.config.id,
            transport: SyncTransportKind.holePunch.id,
          ),
        );
        final pair = [identity.id, peer.deviceId]..sort();
        final token = '${pair.first}/${pair.last}/${folder.infohash}';
        final punch = await holePunch(
          channel: channel,
          initiator: initiator,
          token: token,
        );
        if (punch == null) throw const SyncTransportUnavailable(null);
        return KcpLink(peerId: peer.deviceId, punch: punch);
      },
    );

    yield SyncTransportCandidate(
      descriptor: const SyncTransportDescriptor(
        kind: SyncTransportKind.localNetwork,
        priority: 10,
        available: true,
      ),
      open: () async {
        final initiator = identity.id.compareTo(peer.deviceId) < 0;
        onAttempt(SyncTransportKind.localNetwork.id);
        onEvent?.call(
          SyncEvent(
            SyncEventKind.connecting,
            peerId: peer.deviceId,
            folderId: folder.config.id,
            transport: SyncTransportKind.localNetwork.id,
          ),
        );
        _log('negotiate "${folder.config.label}" initiator=$initiator');
        return negotiate(
          peerId: peer.deviceId,
          channel: channel,
          initiator: initiator,
          iceServers: config.iceServers,
        );
      },
    );

    yield _offlineCandidate(
      SyncTransportKind.wifiDirect,
      12,
      config.wifiDirectDiscovery && _wifiDirectSupported,
      peer,
      folder,
      () => _wifiDirect.open(peerId: peer.deviceId, folderId: folder.config.id),
      onAttempt: onAttempt,
    );

    yield _offlineCandidate(
      SyncTransportKind.multipeer,
      13,
      config.multipeerDiscovery && _multipeerSupported,
      peer,
      folder,
      () => _multipeer.open(peerId: peer.deviceId, folderId: folder.config.id),
      onAttempt: onAttempt,
    );

    yield _offlineCandidate(
      SyncTransportKind.wifiAware,
      14,
      config.wifiAwareDiscovery && _wifiAwareSupported,
      peer,
      folder,
      () => _wifiAware.open(peerId: peer.deviceId, folderId: folder.config.id),
      onAttempt: onAttempt,
    );

    yield _offlineCandidate(
      SyncTransportKind.bluetooth,
      20,
      config.bluetoothDiscovery,
      peer,
      folder,
      () => _bluetooth.open(peerId: peer.deviceId, folderId: folder.config.id),
      onAttempt: onAttempt,
    );
  }

  Iterable<SyncTransportCandidate> _offlineCandidates({
    required FolderRuntime folder,
    required PairingPayload peer,
  }) sync* {
    yield _offlineCandidate(
      SyncTransportKind.wifiDirect,
      12,
      config.wifiDirectDiscovery && _wifiDirectSupported,
      peer,
      folder,
      () => _wifiDirect.open(peerId: peer.deviceId, folderId: folder.config.id),
    );
    yield _offlineCandidate(
      SyncTransportKind.multipeer,
      13,
      config.multipeerDiscovery && _multipeerSupported,
      peer,
      folder,
      () => _multipeer.open(peerId: peer.deviceId, folderId: folder.config.id),
    );
    yield _offlineCandidate(
      SyncTransportKind.wifiAware,
      14,
      config.wifiAwareDiscovery && _wifiAwareSupported,
      peer,
      folder,
      () => _wifiAware.open(peerId: peer.deviceId, folderId: folder.config.id),
    );
    yield _offlineCandidate(
      SyncTransportKind.bluetooth,
      20,
      config.bluetoothDiscovery,
      peer,
      folder,
      () => _bluetooth.open(peerId: peer.deviceId, folderId: folder.config.id),
    );
  }

  SyncTransportCandidate _offlineCandidate(
    SyncTransportKind kind,
    int priority,
    bool available,
    PairingPayload peer,
    FolderRuntime folder,
    Future<PeerLink> Function() open, {
    void Function(String transport)? onAttempt,
  }) => SyncTransportCandidate(
    descriptor: SyncTransportDescriptor(
      kind: kind,
      priority: priority,
      available: available,
    ),
    open: () {
      onAttempt?.call(kind.id);
      onEvent?.call(
        SyncEvent(
          SyncEventKind.connecting,
          peerId: peer.deviceId,
          folderId: folder.config.id,
          transport: kind.id,
        ),
      );
      return open();
    },
  );

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
    _offlineTimer?.cancel();
    _relayTimer?.cancel();
    for (final timer in _debounce.values) {
      timer.cancel();
    }
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _beacon?.stop();
    await _signalMap?.dispose();
    await _dataMap?.dispose();
    for (final dht in _dhts) {
      await dht.stop();
    }
    await _bluetooth.stop();
    await _wifiDirect.stop();
    await _wifiAware.stop();
    await _multipeer.stop();
    await _tcp.stop();
    await _signaling.stop();
  }
}
