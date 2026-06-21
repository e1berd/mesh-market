import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../core/config.dart';
import 'messages.dart';
import 'peer_link.dart';

class WebRtcLink implements PeerLink {
  WebRtcLink(this.peerId, this._channel) {
    _channel.onMessage = (message) {
      if (message.isBinary) _incoming.add(SyncMessage.decode(message.binary));
    };
    _channel.onDataChannelState = (state) {
      if (state == RTCDataChannelState.RTCDataChannelClosed ||
          state == RTCDataChannelState.RTCDataChannelClosing) {
        _closeIncoming();
      }
    };
  }

  @override
  final String peerId;

  final RTCDataChannel _channel;
  final _incoming = StreamController<SyncMessage>();

  @override
  Stream<SyncMessage> get incoming => _incoming.stream;

  @override
  Future<void> send(SyncMessage message) =>
      _channel.send(RTCDataChannelMessage.fromBinary(message.encode()));

  @override
  Future<void> close() async {
    await _channel.close();
    await _closeIncoming();
  }

  Future<void> _closeIncoming() async {
    if (!_incoming.isClosed) await _incoming.close();
  }
}

Future<RTCPeerConnection> createSyncConnection(List<IceServer> iceServers) =>
    createPeerConnection({
      'iceServers': [for (final server in iceServers) server.toWebRtc()],
    });
