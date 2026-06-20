import 'dart:typed_data';

class Device {
  const Device({
    required this.id,
    required this.name,
    this.online = false,
    this.lastSeen,
  });

  final String id;
  final String name;
  final bool online;
  final DateTime? lastSeen;
}

class FolderConfig {
  const FolderConfig({
    required this.id,
    required this.label,
    required this.localPath,
    required this.swarmSecret,
    this.peerIds = const [],
  });

  final String id;
  final String label;
  final String localPath;
  final List<int> swarmSecret;
  final List<String> peerIds;
}

class FileMeta {
  const FileMeta({
    required this.path,
    required this.size,
    required this.modified,
    required this.blockHashes,
    this.deleted = false,
  });

  final String path;
  final int size;
  final DateTime modified;
  final List<String> blockHashes;
  final bool deleted;
}

class FileBlock {
  const FileBlock({required this.index, required this.hash, required this.bytes});

  final int index;
  final String hash;
  final Uint8List bytes;
}
