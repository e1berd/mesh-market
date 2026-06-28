import 'dart:io';

import '../core/folder_share.dart';
import '../core/pairing.dart';
import '../sync/sync_event.dart';
import '../transport/lan_beacon.dart';

class PairPrompt {
  PairPrompt(this.id, this.requester, this.code);
  final String id;
  final PairingPayload requester;
  final String code;
}

class SharePrompt {
  SharePrompt(this.id, this.share, this.fromDeviceId);
  final String id;
  final FolderShare share;
  final String fromDeviceId;
}

abstract class SyncController {
  Stream<SyncEvent> get events;
  Stream<SyncProgress> get progress;
  Stream<LanPeer> get nearby;
  Stream<String> get folderChanged;
  Stream<PairingPayload> get paired;
  Stream<PairPrompt> get incomingPairs;
  Stream<SharePrompt> get incomingShares;

  void resolvePair(String id, bool accepted);
  void resolveShare(String id, bool accepted);

  void setSyncActive(bool active);
  Future<void> reloadPeers();
  Future<void> reloadFolders();
  Future<void> reloadConfig();

  Future<int> folderSize(String folderId);
  Future<void> rescan(String folderId);

  Future<bool> pairAt(InternetAddress address, int port);
  Future<bool> pairViaCode(String code);
  Future<bool> shareFolderWith(FolderShare share, PairingPayload peer);

  Future<void> dispose();
}
