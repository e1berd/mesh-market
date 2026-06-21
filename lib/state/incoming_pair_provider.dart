import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/pairing.dart';

class IncomingPair {
  IncomingPair(this.payload, this.code, this._completer);

  final PairingPayload payload;
  final String code;
  final Completer<bool> _completer;

  void respond(bool accept) {
    if (!_completer.isCompleted) _completer.complete(accept);
  }
}

final incomingPairProvider =
    NotifierProvider<IncomingPairNotifier, List<IncomingPair>>(
        IncomingPairNotifier.new);

class IncomingPairNotifier extends Notifier<List<IncomingPair>> {
  @override
  List<IncomingPair> build() => const [];

  Future<bool> request(PairingPayload payload, String code) {
    final completer = Completer<bool>();
    final pending = IncomingPair(payload, code, completer);
    state = [...state, pending];
    return completer.future
        .timeout(const Duration(seconds: 60), onTimeout: () => false)
        .whenComplete(() => state = [...state]..remove(pending));
  }

  void resolve(IncomingPair pending, bool accept) => pending.respond(accept);
}
