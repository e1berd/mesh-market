import 'package:point_machine/core/folder_share.dart';
import 'package:test/test.dart';

void main() {
  test('folder share round-trips id, label and swarm secret', () {
    final decoded = FolderShare.decode(
      const FolderShare(folderId: 'f1', label: 'Docs', swarmSecret: [1, 2, 3])
          .encode(),
    );
    expect(decoded.folderId, equals('f1'));
    expect(decoded.label, equals('Docs'));
    expect(decoded.swarmSecret, equals([1, 2, 3]));
  });
}
