enum SyncEventKind { connecting, connected, disconnected, received, conflict }

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
