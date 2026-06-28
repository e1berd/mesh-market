enum SyncEventKind { connecting, connected, disconnected, received, conflict }

enum SyncDirection { incoming, outgoing }

class SyncProgress {
  const SyncProgress({
    required this.peerId,
    required this.folderId,
    required this.direction,
    required this.done,
    required this.total,
    required this.active,
  });

  final String peerId;
  final String folderId;
  final SyncDirection direction;
  final int done;
  final int total;
  final bool active;

  String get key => '$peerId/$folderId/${direction.name}';
}

class SyncEvent {
  SyncEvent(
    this.kind, {
    this.peerId,
    this.folderId,
    this.transport,
    this.path,
    DateTime? at,
  }) : at = at ?? DateTime.now();

  final SyncEventKind kind;
  final String? peerId;
  final String? folderId;
  final String? transport;
  final String? path;
  final DateTime at;

  SyncEvent withContext({
    required String peerId,
    required String folderId,
    String? transport,
  }) => SyncEvent(
    kind,
    peerId: peerId,
    folderId: folderId,
    transport: transport ?? this.transport,
    path: path,
    at: at,
  );
}
