import 'dart:async';

import 'package:point_machine/transport/messages.dart';
import 'package:point_machine/transport/peer_link.dart';
import 'package:point_machine/transport/sync_transport.dart';
import 'package:test/test.dart';

class _FakeLink implements PeerLink {
  _FakeLink(this.peerId);

  @override
  final String peerId;

  @override
  Stream<SyncMessage> get incoming => const Stream.empty();

  @override
  Future<void> send(SyncMessage message) async {}

  @override
  Future<void> close() async {}
}

void main() {
  const target = SyncTransportTarget(
    peerId: 'peer',
    folderId: 'folder',
    folderLabel: 'Folder',
  );

  test('opens the highest priority available transport', () async {
    final coordinator = SyncTransportCoordinator();

    final result = await coordinator.open(target, [
      SyncTransportCandidate(
        descriptor: const SyncTransportDescriptor(
          kind: SyncTransportKind.bluetooth,
          priority: 20,
          available: true,
        ),
        open: () async => _FakeLink('peer'),
      ),
      SyncTransportCandidate(
        descriptor: const SyncTransportDescriptor(
          kind: SyncTransportKind.localNetwork,
          priority: 10,
          available: true,
        ),
        open: () async => _FakeLink('peer'),
      ),
    ]);

    expect(result.kind, SyncTransportKind.localNetwork);
  });

  test('falls back and cools down a failing transport', () async {
    var now = DateTime(2026);
    var lanAttempts = 0;
    final coordinator = SyncTransportCoordinator(clock: () => now);

    Future<SyncTransportOpenResult> open() => coordinator.open(target, [
      SyncTransportCandidate(
        descriptor: const SyncTransportDescriptor(
          kind: SyncTransportKind.localNetwork,
          priority: 10,
          available: true,
        ),
        open: () async {
          lanAttempts++;
          throw StateError('offline');
        },
      ),
      SyncTransportCandidate(
        descriptor: const SyncTransportDescriptor(
          kind: SyncTransportKind.bluetooth,
          priority: 20,
          available: true,
        ),
        open: () async => _FakeLink('peer'),
      ),
    ]);

    expect((await open()).kind, SyncTransportKind.bluetooth);
    expect((await open()).kind, SyncTransportKind.bluetooth);
    expect(lanAttempts, 1);

    now = now.add(const Duration(seconds: 6));
    expect((await open()).kind, SyncTransportKind.bluetooth);
    expect(lanAttempts, 2);
  });
}
