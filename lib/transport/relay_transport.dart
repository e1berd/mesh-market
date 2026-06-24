import 'dart:async';
import 'dart:convert';

import 'messages.dart';
import 'peer_link.dart';
import 'signaling.dart';

class RelayPeerLink implements PeerLink {
  RelayPeerLink({
    required this.peerId,
    required this._channel,
    required this._token,
  }) {
    _subscription = _channel.incoming.listen(
      (message) {
        if (message is RelayFrame && message.token == _token) {
          try {
            _incoming.add(SyncMessage.decode(base64Decode(message.data)));
          } on Object {
            return;
          }
        } else if (message is RelayEnd && message.token == _token) {
          unawaited(_closeIncoming());
        }
      },
      onError: (_) => _closeIncoming(),
      onDone: _closeIncoming,
    );
  }

  @override
  final String peerId;

  final SignalChannel _channel;
  final String _token;
  final _incoming = StreamController<SyncMessage>();
  late final StreamSubscription<SignalMessage> _subscription;

  @override
  Stream<SyncMessage> get incoming => _incoming.stream;

  @override
  Future<void> send(SyncMessage message) =>
      _channel.send(RelayFrame(_token, base64Encode(message.encode())));

  @override
  Future<void> close() async {
    try {
      await _channel.send(RelayEnd(_token));
    } on Object {
      // peer may already be gone
    }
    await _subscription.cancel();
    await _channel.close();
    await _closeIncoming();
  }

  Future<void> _closeIncoming() async {
    if (!_incoming.isClosed) await _incoming.close();
  }
}

Future<void> bridgeRelay(
  String token,
  SignalChannel a,
  SignalChannel b,
) async {
  final done = Completer<void>();
  void finish() {
    if (!done.isCompleted) done.complete();
  }

  StreamSubscription<SignalMessage> wire(SignalChannel from, SignalChannel to) =>
      from.incoming.listen(
        (message) {
          if (message is RelayFrame && message.token == token) {
            unawaited(to.send(message));
          } else if (message is RelayEnd && message.token == token) {
            finish();
          }
        },
        onError: (_) => finish(),
        onDone: finish,
      );

  final subs = [wire(a, b), wire(b, a)];
  try {
    await done.future;
  } finally {
    for (final sub in subs) {
      await sub.cancel();
    }
    await a.close();
    await b.close();
  }
}
