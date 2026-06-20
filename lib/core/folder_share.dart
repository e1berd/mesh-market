import 'dart:convert';

class FolderShare {
  const FolderShare({
    required this.folderId,
    required this.label,
    required this.swarmSecret,
  });

  factory FolderShare.decode(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return FolderShare(
      folderId: json['id'] as String,
      label: json['label'] as String,
      swarmSecret: base64Decode(json['swarm'] as String),
    );
  }

  final String folderId;
  final String label;
  final List<int> swarmSecret;

  String encode() => jsonEncode({
        'id': folderId,
        'label': label,
        'swarm': base64Encode(swarmSecret),
      });
}
