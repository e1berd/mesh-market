import 'messages.dart';

abstract interface class PeerLink {
  String get peerId;
  Stream<SyncMessage> get incoming;
  Future<void> send(SyncMessage message);
  Future<void> close();
}
