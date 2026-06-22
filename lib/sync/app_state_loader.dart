import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sembast/sembast_io.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config.dart';
import '../core/device_name.dart';
import '../core/folder_codec.dart';
import '../core/identity.dart';
import '../core/models.dart';
import '../core/pairing.dart';

const _configKey = 'app_config';

Future<DeviceIdentity> loadIdentity(Directory dir) =>
    IdentityService(File(p.join(dir.path, 'identity.json'))).loadOrCreate();

Future<String> loadDeviceName(Directory dir) async {
  final file = File(p.join(dir.path, 'device_name.json'));
  final stored = await _readDeviceName(file);
  if (stored != null && stored.isNotEmpty) return stored;

  final identity = await loadIdentity(dir);
  final generated = randomDeviceName(identity.id);
  await file.writeAsString(jsonEncode({'name': generated}));
  return generated;
}

Future<String?> _readDeviceName(File file) async {
  if (!await file.exists()) return null;
  try {
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return (json['name'] as String? ?? '').trim();
  } on Object {
    return null;
  }
}

Future<AppConfig> loadConfig() async {
  final prefs = await SharedPreferences.getInstance();
  final json = prefs.getString(_configKey);
  if (json == null) return const AppConfig();
  return AppConfig.fromJson(
    Map<String, dynamic>.from(jsonDecode(json) as Map<String, dynamic>),
  );
}

Future<List<PairingPayload>> loadPeers(Directory dir) async {
  final file = File(p.join(dir.path, 'peers.json'));
  if (!await file.exists()) return const [];
  final list = jsonDecode(await file.readAsString()) as List;
  return [
    for (final item in list)
      PairingPayload.fromJson((item as Map).cast<String, Object?>()),
  ];
}

Future<void> savePeers(Directory dir, List<PairingPayload> peers) async {
  final file = File(p.join(dir.path, 'peers.json'));
  await file.writeAsString(jsonEncode([for (final p in peers) p.toJson()]));
}

Future<List<FolderConfig>> loadFolders(Directory dir) async {
  final file = File(p.join(dir.path, 'folders.json'));
  if (!await file.exists()) return const [];
  return foldersFromJson(await file.readAsString());
}

Future<Database> loadDatabase(Directory dir) =>
    databaseFactoryIo.openDatabase(p.join(dir.path, 'point-machine.db'));
