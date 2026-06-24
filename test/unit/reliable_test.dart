import 'dart:math';
import 'dart:typed_data';

import 'package:mesh_market/transport/holepunch/reliable.dart';
import 'package:test/test.dart';

void main() {
  group('ReliableTransport', () {
    test('delivers a fragmented message intact', () async {
      final pair = _Pair();
      final received = pair.b.messages.first;
      final payload = _bytes(5000);
      pair.a.sendMessage(payload);
      await pair.pump();
      expect(await received, payload);
      pair.dispose();
    });

    test('recovers from packet loss and reordering', () async {
      final pair = _Pair(lossRate: 0.3, reorder: true, seed: 7);
      final messages = <Uint8List>[];
      final done = pair.b.messages.take(20).forEach(messages.add);
      final sent = [for (var i = 0; i < 20; i++) _bytes(300 + i * 137)];
      for (final message in sent) {
        pair.a.sendMessage(message);
      }
      await pair.pump(ticks: 400);
      await done;
      expect(messages, sent);
      pair.dispose();
    });

    test('delivers in order despite out-of-order completion', () async {
      final pair = _Pair(lossRate: 0.2, reorder: true, seed: 42);
      final messages = <Uint8List>[];
      final done = pair.b.messages.take(10).forEach(messages.add);
      for (var i = 0; i < 10; i++) {
        pair.a.sendMessage(Uint8List.fromList([i]));
      }
      await pair.pump(ticks: 200);
      await done;
      expect([for (final m in messages) m.first], [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
      pair.dispose();
    });
  });
}

Uint8List _bytes(int length) =>
    Uint8List.fromList([for (var i = 0; i < length; i++) (i * 31 + 7) & 0xff]);

class _Pair {
  _Pair({this.lossRate = 0, this.reorder = false, int seed = 1})
    : _random = Random(seed) {
    a = ReliableTransport(
      send: (d) => _carry(d, toB: true),
      rto: _rto,
      clock: () => _now,
    );
    b = ReliableTransport(
      send: (d) => _carry(d, toB: false),
      rto: _rto,
      clock: () => _now,
    );
  }

  static const _rto = Duration(milliseconds: 20);

  final double lossRate;
  final bool reorder;
  final Random _random;
  late final ReliableTransport a;
  late final ReliableTransport b;
  final _toB = <Uint8List>[];
  final _toA = <Uint8List>[];
  var _now = DateTime.fromMillisecondsSinceEpoch(1000000);

  void _carry(Uint8List datagram, {required bool toB}) {
    if (lossRate > 0 && _random.nextDouble() < lossRate) return;
    final copy = Uint8List.fromList(datagram);
    final queue = toB ? _toB : _toA;
    if (reorder && queue.isNotEmpty && _random.nextBool()) {
      queue.insert(0, copy);
    } else {
      queue.add(copy);
    }
  }

  Future<void> pump({int ticks = 100}) async {
    for (var i = 0; i < ticks; i++) {
      while (_toB.isNotEmpty) {
        b.onDatagram(_toB.removeAt(0));
      }
      while (_toA.isNotEmpty) {
        a.onDatagram(_toA.removeAt(0));
      }
      _now = _now.add(_rto * 2);
      a.tick();
      b.tick();
      await Future<void>.delayed(Duration.zero);
    }
  }

  void dispose() {
    a.close();
    b.close();
  }
}
