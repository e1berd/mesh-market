import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sembast/sembast_io.dart';

import '../core/device_name.dart';
import '../core/identity.dart';
import '../core/paths.dart';

final identityProvider = FutureProvider<DeviceIdentity>((ref) async {
  final dir = await appDataDir();
  return IdentityService(
    File(p.join(dir.path, 'identity.json')),
  ).loadOrCreate();
});

final databaseProvider = FutureProvider<Database>((ref) async {
  final dir = await appDataDir();
  return databaseFactoryIo.openDatabase(p.join(dir.path, 'point-machine.db'));
});

final deviceNameProvider = AsyncNotifierProvider<DeviceNameNotifier, String>(
  DeviceNameNotifier.new,
);

class DeviceNameNotifier extends AsyncNotifier<String> {
  late File _file;

  @override
  Future<String> build() async {
    final dir = await appDataDir();
    _file = File(p.join(dir.path, 'device_name.json'));
    final stored = await _readStored();
    if (stored != null && stored.isNotEmpty) return stored;

    final identity = await ref.watch(identityProvider.future);
    final generated = randomDeviceName(identity.id);
    await _write(generated);
    return generated;
  }

  Future<String?> _readStored() async {
    if (!await _file.exists()) return null;
    try {
      final json =
          jsonDecode(await _file.readAsString()) as Map<String, dynamic>;
      return _sanitize(json['name'] as String? ?? '');
    } on Object {
      return null;
    }
  }

  Future<void> rename(String name) async {
    final next = _sanitize(name);
    if (next.isEmpty) {
      throw const FormatException('Device name cannot be empty');
    }

    await _write(next);
    state = AsyncData(next);
  }

  Future<void> _write(String name) =>
      _file.writeAsString(jsonEncode({'name': name}));
}

String defaultDeviceName() {
  final hostname = _hostname();
  return _isUsableHostname(hostname) ? hostname : 'Point Machine';
}

String _hostname() {
  try {
    return _sanitize(Platform.localHostname);
  } on Object {
    return '';
  }
}

String _sanitize(String name) {
  return name.trim().replaceAll(RegExp(r'\s+'), ' ');
}

bool _isUsableHostname(String hostname) {
  final lower = hostname.toLowerCase();
  return lower.isNotEmpty &&
      lower != 'localhost' &&
      lower != 'localhost.localdomain' &&
      !lower.startsWith('localhost.');
}
