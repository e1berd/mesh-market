import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sembast/sembast_io.dart';

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
    if (!await _file.exists()) return defaultDeviceName();

    try {
      final json =
          jsonDecode(await _file.readAsString()) as Map<String, dynamic>;
      final stored = _sanitize(json['name'] as String? ?? '');
      return stored.isEmpty ? defaultDeviceName() : stored;
    } on Object {
      return defaultDeviceName();
    }
  }

  Future<void> rename(String name) async {
    final next = _sanitize(name);
    if (next.isEmpty) {
      throw const FormatException('Device name cannot be empty');
    }

    await _file.writeAsString(jsonEncode({'name': next}));
    state = AsyncData(next);
  }
}

String defaultDeviceName() {
  try {
    final hostname = _sanitize(Platform.localHostname);
    if (_isUsableHostname(hostname)) return hostname;
  } on Object {
    // Fall through to the app-level default.
  }

  return 'Point Machine';
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
