import 'dart:async';
import 'dart:io';

import 'package:bittorrent_dht/bittorrent_dht.dart';

class DiscoveredPeer {
  const DiscoveredPeer(this.address, this.port);

  final InternetAddress address;
  final int port;
}

class DhtDiscovery {
  DhtDiscovery({required this.infohash, required this.servicePort});

  final String infohash;
  final int servicePort;

  final _dht = DHT();
  final _peers = StreamController<DiscoveredPeer>.broadcast();

  Stream<DiscoveredPeer> get peers => _peers.stream;

  Future<void> start() async {
    _dht.createListener()
      ..on<NewPeerEvent>((event) {
        if (event.infoHash == infohash) {
          _peers.add(DiscoveredPeer(event.address.address, event.address.port));
        }
      })
      ..on<DHTError>((_) {});
    await _dht.bootstrap();
    _dht
      ..announce(infohash, servicePort)
      ..requestPeers(infohash);
  }

  Future<void> stop() async {
    _dht.stop();
    await _peers.close();
  }
}
