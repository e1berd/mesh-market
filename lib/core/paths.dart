import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<Directory> appDataDir() async {
  final base = await getApplicationSupportDirectory();
  final dir = Directory(p.join(base.path, 'point-machine'));
  await dir.create(recursive: true);
  return dir;
}
