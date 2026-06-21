import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../transport/lan_beacon.dart';
import 'sync_provider.dart';

final nearbyDevicesProvider = StreamProvider<List<LanPeer>>((ref) async* {
  final service = await ref.watch(syncServiceProvider.future);
  final seen = <String, (LanPeer, DateTime)>{};
  yield const [];
  await for (final peer in service.nearby) {
    final now = DateTime.now();
    seen[peer.deviceId] = (peer, now);
    seen.removeWhere(
      (_, value) => now.difference(value.$2) > const Duration(seconds: 45),
    );
    yield [for (final value in seen.values) value.$1];
  }
});
