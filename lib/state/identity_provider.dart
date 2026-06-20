import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sembast/sembast_io.dart';

import '../core/identity.dart';
import '../core/paths.dart';

final identityProvider = FutureProvider<DeviceIdentity>((ref) async {
  final dir = await appDataDir();
  return IdentityService(File(p.join(dir.path, 'identity.json'))).loadOrCreate();
});

final databaseProvider = FutureProvider<Database>((ref) async {
  final dir = await appDataDir();
  return databaseFactoryIo.openDatabase(p.join(dir.path, 'point-machine.db'));
});

final deviceNameProvider = Provider<String>((ref) {
  try {
    return Platform.localHostname;
  } on Object {
    return 'point-machine';
  }
});
