import 'dart:convert';

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
