import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/folder_share.dart';

class IncomingShare {
  IncomingShare(this.share, this.fromDeviceId, this._completer);

  final FolderShare share;
  final String fromDeviceId;
  final Completer<bool> _completer;

  void respond(bool accept) {
    if (!_completer.isCompleted) _completer.complete(accept);
  }
}

final incomingShareProvider =
    NotifierProvider<IncomingShareNotifier, List<IncomingShare>>(
        IncomingShareNotifier.new);

class IncomingShareNotifier extends Notifier<List<IncomingShare>> {
  @override
  List<IncomingShare> build() => const [];

  Future<bool> request(FolderShare share, String fromDeviceId) {
    debugPrint('[pm.share] request "${share.label}" from $fromDeviceId');
    for (final existing in state) {
      if (existing.share.folderId == share.folderId &&
          existing.fromDeviceId == fromDeviceId) {
        debugPrint('[pm.share] duplicate share ignored');
        return Future.value(false);
      }
    }
    final completer = Completer<bool>();
    final pending = IncomingShare(share, fromDeviceId, completer);
    state = [...state, pending];
    return completer.future
        .timeout(const Duration(seconds: 120), onTimeout: () => false)
        .whenComplete(() => state = [...state]..remove(pending));
  }

  void resolve(IncomingShare pending, bool accept) => pending.respond(accept);
}
