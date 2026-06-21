import 'peer_link.dart';

enum SyncTransportKind { directTcp, localNetwork, bluetooth }

extension SyncTransportKindLabel on SyncTransportKind {
  String get id => switch (this) {
    SyncTransportKind.directTcp => 'tcp',
    SyncTransportKind.localNetwork => 'lan',
    SyncTransportKind.bluetooth => 'bluetooth',
  };

  String get label => switch (this) {
    SyncTransportKind.directTcp => 'TCP',
    SyncTransportKind.localNetwork => 'Local network',
    SyncTransportKind.bluetooth => 'Bluetooth',
  };
}

class SyncTransportDescriptor {
  const SyncTransportDescriptor({
    required this.kind,
    required this.priority,
    required this.available,
  });

  final SyncTransportKind kind;
  final int priority;
  final bool available;
}

class SyncTransportTarget {
  const SyncTransportTarget({
    required this.peerId,
    required this.folderId,
    required this.folderLabel,
  });

  final String peerId;
  final String folderId;
  final String folderLabel;
}

class SyncTransportCandidate {
  const SyncTransportCandidate({required this.descriptor, required this.open});

  final SyncTransportDescriptor descriptor;
  final Future<PeerLink> Function() open;
}

class SyncTransportOpenResult {
  const SyncTransportOpenResult({required this.kind, required this.link});

  final SyncTransportKind kind;
  final PeerLink link;
}

class SyncTransportCoordinator {
  SyncTransportCoordinator({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final _failures = <String, _TransportFailure>{};

  Future<SyncTransportOpenResult> open(
    SyncTransportTarget target,
    Iterable<SyncTransportCandidate> candidates,
  ) async {
    final ordered =
        candidates
            .where((candidate) => candidate.descriptor.available)
            .where(
              (candidate) => !_inCooldown(target, candidate.descriptor.kind),
            )
            .toList()
          ..sort(
            (a, b) => a.descriptor.priority.compareTo(b.descriptor.priority),
          );

    Object? lastError;
    for (final candidate in ordered) {
      try {
        final link = await candidate.open();
        _failures.remove(_key(target, candidate.descriptor.kind));
        return SyncTransportOpenResult(
          kind: candidate.descriptor.kind,
          link: link,
        );
      } on Object catch (error) {
        lastError = error;
        _recordFailure(target, candidate.descriptor.kind);
      }
    }

    throw SyncTransportUnavailable(lastError);
  }

  bool _inCooldown(SyncTransportTarget target, SyncTransportKind kind) {
    final failure = _failures[_key(target, kind)];
    if (failure == null) return false;
    return _clock().isBefore(failure.retryAfter);
  }

  void _recordFailure(SyncTransportTarget target, SyncTransportKind kind) {
    final key = _key(target, kind);
    final previous = _failures[key];
    final attempts = (previous?.attempts ?? 0) + 1;
    final delaySeconds = switch (attempts) {
      1 => 5,
      2 => 15,
      3 => 30,
      _ => 60,
    };
    _failures[key] = _TransportFailure(
      attempts: attempts,
      retryAfter: _clock().add(Duration(seconds: delaySeconds)),
    );
  }

  String _key(SyncTransportTarget target, SyncTransportKind kind) =>
      '${target.peerId}/${target.folderId}/${kind.id}';
}

class SyncTransportUnavailable implements Exception {
  const SyncTransportUnavailable(this.cause);

  final Object? cause;

  @override
  String toString() => cause == null
      ? 'No sync transport available'
      : 'No sync transport available: $cause';
}

class _TransportFailure {
  const _TransportFailure({required this.attempts, required this.retryAfter});

  final int attempts;
  final DateTime retryAfter;
}
