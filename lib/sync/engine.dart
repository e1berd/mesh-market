import 'dart:async';
import 'dart:typed_data';

import '../core/models.dart';
import '../core/pairing.dart';
import '../crypto/aead.dart';
import '../storage/file_store.dart';
import '../transport/messages.dart';
import '../transport/peer_link.dart';
import 'blocks.dart';
import 'index.dart';
import 'sync_event.dart';

class SyncEngine {
  SyncEngine({
    required this.index,
    required this.store,
    required this.cipher,
    this.canReceive = true,
    this.canSend = true,
    this.onEvent,
    this.onProgress,
    this.onPeerProgress,
    this.onPeerHello,
  });

  final FolderIndex index;
  final FileStore store;
  final FolderCipher cipher;
  final bool canReceive;
  final bool canSend;
  final void Function(SyncEvent event)? onEvent;
  final void Function(int done, int total)? onProgress;
  final void Function(int done, int total)? onPeerProgress;
  final void Function(PairingPayload peer)? onPeerHello;

  final _downloads = <String, _Download>{};
  int _filesDone = 0;
  int _filesTotal = 0;
  PeerLink? _link;

  void _emitProgress() {
    onProgress?.call(_filesDone, _filesTotal);
    final link = _link;
    if (link != null) unawaited(link.send(Progress(_filesDone, _filesTotal)));
  }

  Future<void> announce(PeerLink link) async =>
      link.send(IndexSnapshot(await index.all()));

  Future<void> sync(PeerLink link) async {
    _link = link;
    await announce(link);
    await for (final message in link.incoming) {
      switch (message) {
        case IndexSnapshot snapshot:
          if (canReceive) {
            for (final entry in snapshot.entries) {
              await _consider(entry, link);
            }
          }
        case WantBlock want:
          if (canSend) {
            await _serve(want, link);
          }
        case BlockPayload payload:
          await _receive(payload);
        case Progress progress:
          onPeerProgress?.call(progress.done, progress.total);
        case OpenLink():
          continue;
        case Hello hello:
          final payload = hello.payload;
          if (payload != null) onPeerHello?.call(payload);
        case Bye():
          return;
      }
    }
  }

  Future<void> _consider(IndexEntry remote, PeerLink link) async {
    final path = remote.meta.path;
    final local = await index.get(path);
    if (local != null && local.version.dominates(remote.version)) return;

    if (remote.meta.deleted) {
      await store.delete(path);
      await index.put(remote);
      return;
    }

    final divergent = local != null && !local.meta.deleted;
    if (divergent &&
        _sameContent(local.meta.blockHashes, remote.meta.blockHashes)) {
      await index.put(
        IndexEntry(local.meta, local.version.merge(remote.version)),
      );
      return;
    }

    if (divergent && local.version.concurrentWith(remote.version)) {
      await index.put(
        IndexEntry(local.meta, local.version.merge(remote.version)),
      );
      onEvent?.call(SyncEvent(SyncEventKind.conflict, path: path));
      await _download(remote, _conflictPath(path), path, local, link);
    } else {
      await _download(remote, path, path, local, link);
    }
  }

  Future<void> _download(
    IndexEntry remote,
    String targetPath,
    String requestPath,
    IndexEntry? local,
    PeerLink link,
  ) async {
    final entry = targetPath == remote.meta.path
        ? remote
        : IndexEntry(_renamed(remote.meta, targetPath), remote.version);
    final download = _Download(entry, requestPath);
    _downloads[requestPath] = download;
    _filesTotal++;
    _emitProgress();

    final hashes = remote.meta.blockHashes;
    for (var i = 0; i < hashes.length; i++) {
      final reused = await _reuseLocal(requestPath, i, hashes[i], local);
      if (reused != null) {
        download.blocks[i] = reused;
      } else {
        download.pending++;
        await link.send(WantBlock(requestPath, i));
      }
    }
    await _maybeFinish(requestPath);
  }

  Future<Uint8List?> _reuseLocal(
    String path,
    int index,
    String hash,
    IndexEntry? local,
  ) async {
    if (local == null || index >= local.meta.blockHashes.length) return null;
    if (local.meta.blockHashes[index] != hash) return null;
    return store.readRange(path, index * blockSize, blockSize);
  }

  Future<void> _serve(WantBlock want, PeerLink link) async {
    final bytes = await store.readRange(
      want.path,
      want.index * blockSize,
      blockSize,
    );
    await link.send(
      BlockPayload(want.path, want.index, await cipher.seal(bytes)),
    );
  }

  Future<void> _receive(BlockPayload payload) async {
    final download = _downloads[payload.path];
    if (download == null) return;
    download.blocks[payload.index] = Uint8List.fromList(
      await cipher.open(payload.sealed),
    );
    download.pending--;
    await _maybeFinish(payload.path);
  }

  Future<void> _maybeFinish(String requestPath) async {
    final download = _downloads[requestPath];
    if (download == null || download.pending > 0) return;
    if (download.blocks.any((block) => block == null)) return;

    final builder = BytesBuilder(copy: false);
    for (final block in download.blocks) {
      builder.add(block!);
    }
    await store.writeBytes(download.entry.meta.path, builder.toBytes());
    await index.put(download.entry);
    _downloads.remove(requestPath);
    _filesDone++;
    _emitProgress();
    onEvent?.call(
      SyncEvent(SyncEventKind.received, path: download.entry.meta.path),
    );
  }

  bool _sameContent(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  FileMeta _renamed(FileMeta meta, String path) => FileMeta(
    path: path,
    size: meta.size,
    modified: meta.modified,
    blockHashes: meta.blockHashes,
    deleted: meta.deleted,
  );

  String _conflictPath(String path) {
    final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(
      RegExp('[:.]'),
      '-',
    );
    final slash = path.lastIndexOf('/');
    final dot = path.lastIndexOf('.');
    if (dot <= slash) return '$path.sync-conflict-$stamp';
    return '${path.substring(0, dot)}.sync-conflict-$stamp${path.substring(dot)}';
  }
}

class _Download {
  _Download(this.entry, this.requestPath)
    : blocks = List<Uint8List?>.filled(entry.meta.blockHashes.length, null);

  final IndexEntry entry;
  final String requestPath;
  final List<Uint8List?> blocks;
  int pending = 0;
}
