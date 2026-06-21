enum SyncEventKind { connected, disconnected, received, conflict }

class SyncEvent {
  SyncEvent(
    this.kind, {
    this.peerId,
    this.folderId,
    this.path,
    DateTime? at,
  }) : at = at ?? DateTime.now();

  final SyncEventKind kind;
  final String? peerId;
  final String? folderId;
  final String? path;
  final DateTime at;

  SyncEvent withContext({required String peerId, required String folderId}) =>
      SyncEvent(kind, peerId: peerId, folderId: folderId, path: path, at: at);
}
