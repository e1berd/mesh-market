import 'dart:io';

import 'peer_link.dart';
import 'tcp_transport.dart';

class IpLinkBringup {
  const IpLinkBringup(this._tcp);

  final DirectTcpTransport _tcp;

  Future<PeerLink> connect({
    required String host,
    required int port,
    required String peerId,
    required String folderId,
  }) async {
    final address = await _resolve(host);
    return _tcp.open(
      address: address,
      port: port,
      peerId: peerId,
      folderId: folderId,
    );
  }

  Future<InternetAddress> _resolve(String host) async {
    final parsed = InternetAddress.tryParse(host);
    if (parsed != null) return parsed;
    final lookup = await InternetAddress.lookup(host);
    if (lookup.isEmpty) throw StateError('cannot resolve $host');
    return lookup.first;
  }
}
