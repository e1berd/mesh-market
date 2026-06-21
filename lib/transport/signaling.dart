import 'dart:convert';

import '../core/folder_share.dart';
import '../core/pairing.dart';

sealed class SignalMessage {
  const SignalMessage();

  Map<String, Object?> toJson();

  String encode() => jsonEncode(toJson());

  static SignalMessage decode(String raw) =>
      _fromJson((jsonDecode(raw) as Map).cast<String, Object?>());

  static SignalMessage _fromJson(Map<String, Object?> json) =>
      switch (json['t']) {
        'hello' =>
          SignalHello(json['infohash']! as String, json['id']! as String),
        'pair-req' => PairRequest(
            PairingPayload.fromJson((json['p']! as Map).cast<String, Object?>())),
        'pair-res' => PairResponse(
            PairingPayload.fromJson((json['p']! as Map).cast<String, Object?>())),
        'share-req' => ShareRequest(
            FolderShare.fromJson((json['s']! as Map).cast<String, Object?>()),
            json['id']! as String),
        'share-res' => ShareResponse(json['ok']! as bool),
        'offer' => SdpSignal.offer(json['sdp']! as String),
        'answer' => SdpSignal.answer(json['sdp']! as String),
        'ice' => IceSignal(
            json['candidate'] as String?,
            json['mid'] as String?,
            json['line'] as int?,
          ),
        _ => throw FormatException('unknown signal: ${json['t']}'),
      };
}

final class PairRequest extends SignalMessage {
  const PairRequest(this.payload);

  final PairingPayload payload;

  @override
  Map<String, Object?> toJson() => {'t': 'pair-req', 'p': payload.toJson()};
}

final class PairResponse extends SignalMessage {
  const PairResponse(this.payload);

  final PairingPayload payload;

  @override
  Map<String, Object?> toJson() => {'t': 'pair-res', 'p': payload.toJson()};
}

final class ShareRequest extends SignalMessage {
  const ShareRequest(this.share, this.deviceId);

  final FolderShare share;
  final String deviceId;

  @override
  Map<String, Object?> toJson() =>
      {'t': 'share-req', 's': share.toJson(), 'id': deviceId};
}

final class ShareResponse extends SignalMessage {
  const ShareResponse(this.accepted);

  final bool accepted;

  @override
  Map<String, Object?> toJson() => {'t': 'share-res', 'ok': accepted};
}

final class SignalHello extends SignalMessage {
  const SignalHello(this.infohash, this.deviceId);

  final String infohash;
  final String deviceId;

  @override
  Map<String, Object?> toJson() =>
      {'t': 'hello', 'infohash': infohash, 'id': deviceId};
}

final class SdpSignal extends SignalMessage {
  const SdpSignal.offer(this.sdp) : isOffer = true;
  const SdpSignal.answer(this.sdp) : isOffer = false;

  final String sdp;
  final bool isOffer;

  @override
  Map<String, Object?> toJson() =>
      {'t': isOffer ? 'offer' : 'answer', 'sdp': sdp};
}

final class IceSignal extends SignalMessage {
  const IceSignal(this.candidate, this.sdpMid, this.sdpMLineIndex);

  final String? candidate;
  final String? sdpMid;
  final int? sdpMLineIndex;

  @override
  Map<String, Object?> toJson() => {
        't': 'ice',
        'candidate': candidate,
        'mid': sdpMid,
        'line': sdpMLineIndex,
      };
}

abstract interface class SignalChannel {
  Stream<SignalMessage> get incoming;
  Future<void> send(SignalMessage message);
  Future<void> close();
}
