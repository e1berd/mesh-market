import 'package:path/path.dart' as p;

const conflictMarker = '.sync-conflict-';

bool isConflictPath(String path) => p.basename(path).contains(conflictMarker);

String originalOf(String conflictPath) {
  final dir = p.dirname(conflictPath);
  final name = p.basename(conflictPath);
  final index = name.indexOf(conflictMarker);
  if (index < 0) return conflictPath;
  final after = name.substring(index + conflictMarker.length);
  final dot = after.indexOf('.');
  final extension = dot >= 0 ? after.substring(dot) : '';
  final original = name.substring(0, index) + extension;
  return dir == '.' ? original : p.join(dir, original);
}

class FolderConflict {
  const FolderConflict({
    required this.folderId,
    required this.originalPath,
    required this.conflictPath,
  });

  final String folderId;
  final String originalPath;
  final String conflictPath;

  String get name => p.basename(originalPath);
  String get conflictName => p.basename(conflictPath);
}
