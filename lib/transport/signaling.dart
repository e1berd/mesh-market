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
        'hello' => SignalHello(
            json['infohash']! as String,
            json['id']! as String,
            syncPort: json['sport'] as int?,
            syncAddress: json['saddr'] as String?,
          ),
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
        'relay-open' => RelayOpen(
            json['token']! as String,
            json['from']! as String,
            json['target']! as String,
            json['infohash']! as String,
          ),
        'relay-in' => RelayInbound(
            json['token']! as String,
            json['from']! as String,
            json['infohash']! as String,
          ),
        'relay-ready' => RelayReady(json['token']! as String),
        'relay-fail' => RelayFail(json['token']! as String),
        'relay-frame' =>
          RelayFrame(json['token']! as String, json['data']! as String),
        'relay-end' => RelayEnd(json['token']! as String),
        'punch-offer' => PunchOffer(
            json['token']! as String,
            (json['c']! as List).cast<String>(),
          ),
        'punch-answer' => PunchAnswer(
            json['token']! as String,
            (json['c']! as List).cast<String>(),
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
  const SignalHello(
    this.infohash,
    this.deviceId, {
    this.syncPort,
    this.syncAddress,
  });

  final String infohash;
  final String deviceId;
  final int? syncPort;
  final String? syncAddress;

  @override
  Map<String, Object?> toJson() => {
        't': 'hello',
        'infohash': infohash,
        'id': deviceId,
        if (syncPort != null) 'sport': syncPort,
        if (syncAddress != null) 'saddr': syncAddress,
      };
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

final class RelayOpen extends SignalMessage {
  const RelayOpen(this.token, this.from, this.target, this.infohash);

  final String token;
  final String from;
  final String target;
  final String infohash;

  @override
  Map<String, Object?> toJson() => {
        't': 'relay-open',
        'token': token,
        'from': from,
        'target': target,
        'infohash': infohash,
      };
}

final class RelayInbound extends SignalMessage {
  const RelayInbound(this.token, this.from, this.infohash);

  final String token;
  final String from;
  final String infohash;

  @override
  Map<String, Object?> toJson() => {
        't': 'relay-in',
        'token': token,
        'from': from,
        'infohash': infohash,
      };
}

final class RelayReady extends SignalMessage {
  const RelayReady(this.token);

  final String token;

  @override
  Map<String, Object?> toJson() => {'t': 'relay-ready', 'token': token};
}

final class RelayFail extends SignalMessage {
  const RelayFail(this.token);

  final String token;

  @override
  Map<String, Object?> toJson() => {'t': 'relay-fail', 'token': token};
}

final class RelayFrame extends SignalMessage {
  const RelayFrame(this.token, this.data);

  final String token;
  final String data;

  @override
  Map<String, Object?> toJson() =>
      {'t': 'relay-frame', 'token': token, 'data': data};
}

final class RelayEnd extends SignalMessage {
  const RelayEnd(this.token);

  final String token;

  @override
  Map<String, Object?> toJson() => {'t': 'relay-end', 'token': token};
}

final class PunchOffer extends SignalMessage {
  const PunchOffer(this.token, this.candidates);

  final String token;
  final List<String> candidates;

  @override
  Map<String, Object?> toJson() =>
      {'t': 'punch-offer', 'token': token, 'c': candidates};
}

final class PunchAnswer extends SignalMessage {
  const PunchAnswer(this.token, this.candidates);

  final String token;
  final List<String> candidates;

  @override
  Map<String, Object?> toJson() =>
      {'t': 'punch-answer', 'token': token, 'c': candidates};
}

abstract interface class SignalChannel {
  Stream<SignalMessage> get incoming;
  Future<void> send(SignalMessage message);
  Future<void> close();
}
