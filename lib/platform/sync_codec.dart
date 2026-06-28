import 'dart:io';

import '../core/pairing.dart';
import '../sync/sync_event.dart';
import '../transport/lan_beacon.dart';

InternetAddress parseAddress(String value) => InternetAddress(value);

Map<String, Object?> syncEventToJson(SyncEvent event) => {
  'kind': event.kind.name,
  'peerId': event.peerId,
  'folderId': event.folderId,
  'transport': event.transport,
  'path': event.path,
  'at': event.at.millisecondsSinceEpoch,
};

SyncEvent syncEventFromJson(Map<String, Object?> json) => SyncEvent(
  SyncEventKind.values.byName(json['kind'] as String),
  peerId: json['peerId'] as String?,
  folderId: json['folderId'] as String?,
  transport: json['transport'] as String?,
  path: json['path'] as String?,
  at: DateTime.fromMillisecondsSinceEpoch(json['at'] as int),
);

Map<String, Object?> syncProgressToJson(SyncProgress p) => {
  'peerId': p.peerId,
  'folderId': p.folderId,
  'direction': p.direction.name,
  'done': p.done,
  'total': p.total,
  'active': p.active,
};

SyncProgress syncProgressFromJson(Map<String, Object?> json) => SyncProgress(
  peerId: json['peerId'] as String,
  folderId: json['folderId'] as String,
  direction: SyncDirection.values.byName(json['direction'] as String),
  done: json['done'] as int,
  total: json['total'] as int,
  active: json['active'] as bool,
);

Map<String, Object?> lanPeerToJson(LanPeer peer) => {
  'payload': peer.payload.toJson(),
  'address': peer.address.address,
  'port': peer.port,
  'syncPort': peer.syncPort,
};

LanPeer lanPeerFromJson(Map<String, Object?> json) => LanPeer(
  PairingPayload.fromJson((json['payload'] as Map).cast<String, Object?>()),
  InternetAddress(json['address'] as String),
  json['port'] as int,
  syncPort: json['syncPort'] as int?,
);
