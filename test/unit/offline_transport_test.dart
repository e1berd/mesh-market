import 'dart:async';

import 'package:mesh_market/transport/messages.dart';
import 'package:mesh_market/transport/peer_link.dart';
import 'package:mesh_market/transport/sync_transport.dart';
import 'package:test/test.dart';

class _LoopbackLink implements PeerLink {
  _LoopbackLink(this.peerId, this._outgoing, this._incoming);

  @override
  final String peerId;
  final StreamController<SyncMessage> _outgoing;
  final Stream<SyncMessage> _incoming;

  @override
  Stream<SyncMessage> get incoming => _incoming;

  @override
  Future<void> send(SyncMessage message) async => _outgoing.add(message);

  @override
  Future<void> close() async => _outgoing.close();
}

(_LoopbackLink, _LoopbackLink) _pair() {
  final toA = StreamController<SyncMessage>.broadcast();
  final toB = StreamController<SyncMessage>.broadcast();
  return (
    _LoopbackLink('B', toB, toA.stream),
    _LoopbackLink('A', toA, toB.stream),
  );
}

SyncTransportCandidate _candidate(
  SyncTransportKind kind,
  int priority, {
  bool available = true,
  Future<PeerLink> Function()? open,
}) => SyncTransportCandidate(
  descriptor: SyncTransportDescriptor(
    kind: kind,
    priority: priority,
    available: available,
  ),
  open: open ?? () async => _LoopbackLink('peer', StreamController(), const Stream.empty()),
);

void main() {
  const target = SyncTransportTarget(
    peerId: 'peer',
    folderId: 'folder',
    folderLabel: 'Folder',
  );

  test('new offline kinds expose stable ids and labels', () {
    expect(SyncTransportKind.wifiDirect.id, 'wifi-direct');
    expect(SyncTransportKind.multipeer.id, 'multipeer');
    expect(SyncTransportKind.wifiAware.id, 'wifi-aware');
    expect(SyncTransportKind.wifiDirect.label, 'Wi-Fi Direct');
    expect(SyncTransportKind.multipeer.label, 'Multipeer');
    expect(SyncTransportKind.wifiAware.label, 'Wi-Fi Aware');
  });

  test('wifiDirect outranks multipeer, wifiAware and bluetooth', () async {
    final coordinator = SyncTransportCoordinator();
    final result = await coordinator.open(target, [
      _candidate(SyncTransportKind.bluetooth, 20),
      _candidate(SyncTransportKind.wifiAware, 14),
      _candidate(SyncTransportKind.multipeer, 13),
      _candidate(SyncTransportKind.wifiDirect, 12),
    ]);
    expect(result.kind, SyncTransportKind.wifiDirect);
  });

  test('falls through offline kinds in priority order on failure', () async {
    final coordinator = SyncTransportCoordinator();
    final result = await coordinator.open(target, [
      _candidate(
        SyncTransportKind.wifiDirect,
        12,
        open: () async => throw StateError('no peer'),
      ),
      _candidate(SyncTransportKind.multipeer, 13),
      _candidate(SyncTransportKind.bluetooth, 20),
    ]);
    expect(result.kind, SyncTransportKind.multipeer);
  });

  test('unavailable offline kinds are skipped', () async {
    final coordinator = SyncTransportCoordinator();
    final result = await coordinator.open(target, [
      _candidate(SyncTransportKind.wifiDirect, 12, available: false),
      _candidate(SyncTransportKind.bluetooth, 20),
    ]);
    expect(result.kind, SyncTransportKind.bluetooth);
  });

  test('loopback link carries messages in order and closes', () async {
    final (linkA, linkB) = _pair();
    final received = <SyncMessage>[];
    final sub = linkB.incoming.listen(received.add);

    await linkA.send(const OpenLink('A', 'folder'));
    await linkA.send(WantBlock('notes.txt', 0));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(received.length, 2);
    expect(received.first, isA<OpenLink>());
    expect(received[1], isA<WantBlock>());

    await sub.cancel();
    await linkA.close();
    await linkB.close();
  });
}
