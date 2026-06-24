import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../core/config.dart';
import 'peer.dart';
import 'signaling.dart';

Future<WebRtcLink> negotiate({
  required String peerId,
  required SignalChannel channel,
  required bool initiator,
  required List<IceServer> iceServers,
}) async {
  final connection = await createSyncConnection(iceServers);
  final opened = Completer<RTCDataChannel>();

  connection.onIceConnectionState =
      (state) => debugPrint('[pm.rtc] ice $peerId $state');
  connection.onConnectionState =
      (state) => debugPrint('[pm.rtc] conn $peerId $state');
  connection.onIceCandidate = (candidate) => channel.send(
        IceSignal(candidate.candidate, candidate.sdpMid, candidate.sdpMLineIndex),
      );

  void watch(RTCDataChannel dataChannel) {
    if (dataChannel.state == RTCDataChannelState.RTCDataChannelOpen) {
      if (!opened.isCompleted) opened.complete(dataChannel);
    }
    dataChannel.onDataChannelState = (state) {
      if (state == RTCDataChannelState.RTCDataChannelOpen && !opened.isCompleted) {
        opened.complete(dataChannel);
      }
    };
  }

  if (initiator) {
    watch(await connection.createDataChannel(
      'mesh-market',
      RTCDataChannelInit()..ordered = true,
    ));
    final offer = await connection.createOffer();
    await connection.setLocalDescription(offer);
    await channel.send(SdpSignal.offer(offer.sdp!));
  } else {
    connection.onDataChannel = watch;
  }

  final subscription = channel.incoming.listen((message) async {
    switch (message) {
      case SignalHello() ||
            PairRequest() ||
            PairResponse() ||
            ShareRequest() ||
            ShareResponse() ||
            RelayOpen() ||
            RelayInbound() ||
            RelayReady() ||
            RelayFail() ||
            RelayFrame() ||
            RelayEnd() ||
            PunchOffer() ||
            PunchAnswer():
        return;
      case SdpSignal sdp when sdp.isOffer:
        await connection.setRemoteDescription(RTCSessionDescription(sdp.sdp, 'offer'));
        final answer = await connection.createAnswer();
        await connection.setLocalDescription(answer);
        await channel.send(SdpSignal.answer(answer.sdp!));
      case SdpSignal sdp:
        await connection.setRemoteDescription(RTCSessionDescription(sdp.sdp, 'answer'));
      case IceSignal ice:
        await connection.addCandidate(
          RTCIceCandidate(ice.candidate, ice.sdpMid, ice.sdpMLineIndex),
        );
    }
  });

  try {
    final dataChannel =
        await opened.future.timeout(const Duration(seconds: 25));
    Timer(const Duration(seconds: 3), () {
      subscription.cancel();
      channel.close();
    });
    return WebRtcLink(peerId, dataChannel);
  } on Object {
    await subscription.cancel();
    await connection.close();
    await channel.close();
    rethrow;
  }
}
