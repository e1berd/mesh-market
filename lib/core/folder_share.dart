import 'dart:convert';

class FolderShare {
  const FolderShare({
    required this.folderId,
    required this.label,
    required this.swarmSecret,
  });

  factory FolderShare.fromJson(Map<String, Object?> json) => FolderShare(
        folderId: json['id'] as String,
        label: json['label'] as String,
        swarmSecret: base64Decode(json['swarm'] as String),
      );

  factory FolderShare.decode(String raw) =>
      FolderShare.fromJson((jsonDecode(raw) as Map).cast<String, Object?>());

  final String folderId;
  final String label;
  final List<int> swarmSecret;

  Map<String, Object?> toJson() => {
        'id': folderId,
        'label': label,
        'swarm': base64Encode(swarmSecret),
      };

  String encode() => jsonEncode(toJson());
}
