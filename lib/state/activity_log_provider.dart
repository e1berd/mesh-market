import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../core/paths.dart';
import '../platform/open_path.dart';
import '../sync/sync_event.dart';
import 'app_providers.dart';

final activityLogPathProvider = FutureProvider<String>((ref) async {
  final fallback = p.join((await appDataDir()).path, 'activity.log');
  if (Platform.isAndroid || Platform.isIOS) return fallback;
  final configured = ref.watch(
    configProvider.select((config) => config.activityLogPath),
  );
  if (configured != null && configured.trim().isNotEmpty) return configured;
  return fallback;
});

final activityLogControllerProvider = Provider<ActivityLogController>(
  ActivityLogController.new,
);

class ActivityLogController {
  const ActivityLogController(this.ref);

  final Ref ref;

  Future<String> path() => ref.read(activityLogPathProvider.future);

  Future<void> append(SyncEvent event) async {
    final file = File(await path());
    await file.parent.create(recursive: true);
    await file.writeAsString('${_line(event)}\n', mode: FileMode.append);
  }

  Future<List<SyncEvent>> read({int limit = 100}) async {
    final file = File(await path());
    if (!await file.exists()) return const [];
    final lines = await file.readAsLines();
    final events = <SyncEvent>[];
    for (final line in lines) {
      final event = _parse(line);
      if (event != null) events.add(event);
    }
    final trimmed = events.length > limit
        ? events.sublist(events.length - limit)
        : events;
    return trimmed.reversed.toList();
  }

  Future<void> clear() async {
    final file = File(await path());
    await file.parent.create(recursive: true);
    await file.writeAsString('', flush: true);
  }

  Future<String?> choosePath({String? dialogTitle}) async {
    final current = await path();
    final file = File(current);
    final bytes = await file.exists() ? await file.readAsBytes() : Uint8List(0);
    final selected = await FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      fileName: p.basename(current),
      initialDirectory: p.dirname(current),
      allowedExtensions: const ['log', 'txt'],
      type: FileType.custom,
      bytes: bytes,
    );
    if (selected == null || selected.trim().isEmpty) return null;
    if (!Platform.isAndroid && !Platform.isIOS) {
      ref.read(configProvider.notifier).setActivityLogPath(selected);
      ref.invalidate(activityLogPathProvider);
    }
    return selected;
  }

  Future<bool> openLocation() async {
    final logPath = await path();
    final file = File(logPath);
    if (Platform.isAndroid || Platform.isIOS) {
      final bytes = await file.exists()
          ? await file.readAsBytes()
          : Uint8List(0);
      final exported = await FilePicker.platform.saveFile(
        fileName: p.basename(logPath),
        bytes: bytes,
      );
      return exported != null;
    }
    await file.parent.create(recursive: true);
    return openFolderInFileManager(file.parent.path);
  }

  String _line(SyncEvent event) {
    final fields = {
      'at': event.at.toUtc().toIso8601String(),
      'kind': event.kind.name,
      if (event.peerId != null) 'peer': event.peerId!,
      if (event.folderId != null) 'folder': event.folderId!,
      if (event.transport != null) 'transport': event.transport!,
      if (event.path != null) 'path': event.path!,
    };
    return fields.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join(' ');
  }

  SyncEvent? _parse(String line) {
    if (line.trim().isEmpty) return null;
    var head = line;
    String? path;
    final marker = line.indexOf(' path=');
    if (line.startsWith('path=')) {
      head = '';
      path = line.substring(5);
    } else if (marker >= 0) {
      head = line.substring(0, marker);
      path = line.substring(marker + 6);
    }
    final fields = <String, String>{};
    for (final token in head.split(' ')) {
      final eq = token.indexOf('=');
      if (eq > 0) fields[token.substring(0, eq)] = token.substring(eq + 1);
    }
    final kind = SyncEventKind.values
        .where((value) => value.name == fields['kind'])
        .firstOrNull;
    if (kind == null) return null;
    return SyncEvent(
      kind,
      peerId: fields['peer'],
      folderId: fields['folder'],
      transport: fields['transport'],
      path: path,
      at: DateTime.tryParse(fields['at'] ?? ''),
    );
  }
}
