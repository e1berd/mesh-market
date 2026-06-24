import 'dart:async';
import 'dart:typed_data';

const _data = 1;
const _ack = 2;
const _dataHeader = 9;
const _ackHeader = 7;

class ReliableTransport {
  ReliableTransport({
    required this.send,
    this.maxPayload = 1100,
    this.window = 256 * 1024,
    this.rto = const Duration(milliseconds: 300),
    this.maxRetries = 40,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final void Function(Uint8List datagram) send;
  final int maxPayload;
  final int window;
  final Duration rto;
  final int maxRetries;
  final DateTime Function() _clock;

  final _out = StreamController<Uint8List>();
  final _pending = <int, _OutMessage>{};
  final _queue = <Uint8List>[];
  final _assembling = <int, _InMessage>{};
  final _ready = <int, Uint8List>{};
  int _nextMsgId = 1;
  int _deliverNext = 1;
  int _inFlight = 0;
  bool _closed = false;

  Stream<Uint8List> get messages => _out.stream;

  void sendMessage(Uint8List message) {
    if (_closed) return;
    _queue.add(message);
    _pump();
  }

  void onDatagram(Uint8List datagram) {
    if (_closed || datagram.isEmpty) return;
    switch (datagram[0]) {
      case _data:
        _onData(datagram);
      case _ack:
        _onAck(datagram);
    }
  }

  void tick() {
    if (_closed) return;
    final now = _clock();
    for (final message in _pending.values) {
      for (var i = 0; i < message.count; i++) {
        if (message.acked[i]) continue;
        if (now.difference(message.sentAt[i]) < rto) continue;
        if (++message.tries[i] > maxRetries) {
          _fail();
          return;
        }
        send(message.frame(i));
        message.sentAt[i] = now;
      }
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    if (!_out.isClosed) await _out.close();
  }

  void _pump() {
    while (_queue.isNotEmpty && _inFlight < window) {
      final message = _OutMessage(_nextMsgId++, _queue.removeAt(0), maxPayload);
      _pending[message.id] = message;
      _inFlight += message.bytes;
      final now = _clock();
      for (var i = 0; i < message.count; i++) {
        send(message.frame(i));
        message.sentAt[i] = now;
      }
    }
  }

  void _onData(Uint8List datagram) {
    if (datagram.length < _dataHeader) return;
    final view = ByteData.sublistView(datagram);
    final msgId = view.getUint32(1);
    final frag = view.getUint16(5);
    final count = view.getUint16(7);
    final payload = Uint8List.sublistView(datagram, _dataHeader);
    send(_ackFrame(msgId, frag));
    if (msgId < _deliverNext || _ready.containsKey(msgId)) return;
    final message = _assembling.putIfAbsent(msgId, () => _InMessage(count));
    if (!message.store(frag, payload)) return;
    if (message.complete) {
      _ready[msgId] = message.assemble();
      _assembling.remove(msgId);
      _flush();
    }
  }

  void _onAck(Uint8List datagram) {
    if (datagram.length < _ackHeader) return;
    final view = ByteData.sublistView(datagram);
    final message = _pending[view.getUint32(1)];
    if (message == null) return;
    if (message.ack(view.getUint16(5))) {
      _inFlight -= message.bytes;
      _pending.remove(message.id);
      _pump();
    }
  }

  void _flush() {
    while (_ready.containsKey(_deliverNext)) {
      if (!_out.isClosed) _out.add(_ready.remove(_deliverNext)!);
      _deliverNext++;
    }
  }

  Uint8List _ackFrame(int msgId, int frag) {
    final frame = Uint8List(_ackHeader);
    ByteData.sublistView(frame)
      ..setUint8(0, _ack)
      ..setUint32(1, msgId)
      ..setUint16(5, frag);
    return frame;
  }

  void _fail() {
    if (_closed) return;
    _closed = true;
    if (!_out.isClosed) {
      _out.addError(const ReliableTransportClosed());
      _out.close();
    }
  }
}

class ReliableTransportClosed implements Exception {
  const ReliableTransportClosed();

  @override
  String toString() => 'reliable transport peer unreachable';
}

class _OutMessage {
  _OutMessage(this.id, Uint8List message, int maxPayload)
    : count = message.isEmpty ? 1 : (message.length + maxPayload - 1) ~/ maxPayload,
      bytes = message.length {
    _frags = List.generate(count, (i) {
      final start = i * maxPayload;
      final end = start + maxPayload < message.length
          ? start + maxPayload
          : message.length;
      return Uint8List.sublistView(message, start, end);
    });
    acked = List.filled(count, false);
    tries = List.filled(count, 0);
    sentAt = List.filled(count, DateTime.fromMillisecondsSinceEpoch(0));
  }

  final int id;
  final int count;
  final int bytes;
  late final List<Uint8List> _frags;
  late final List<bool> acked;
  late final List<int> tries;
  late final List<DateTime> sentAt;
  int _remaining = -1;

  Uint8List frame(int index) {
    final payload = _frags[index];
    final frame = Uint8List(_dataHeader + payload.length);
    ByteData.sublistView(frame)
      ..setUint8(0, _data)
      ..setUint32(1, id)
      ..setUint16(5, index)
      ..setUint16(7, count);
    frame.setRange(_dataHeader, frame.length, payload);
    return frame;
  }

  bool ack(int index) {
    if (index >= count || acked[index]) return _remaining == 0;
    acked[index] = true;
    if (_remaining < 0) _remaining = count;
    _remaining--;
    return _remaining == 0;
  }
}

class _InMessage {
  _InMessage(this.count)
    : frags = List<Uint8List?>.filled(count == 0 ? 1 : count, null);

  final int count;
  final List<Uint8List?> frags;
  int _have = 0;

  bool store(int index, Uint8List payload) {
    if (index >= frags.length || frags[index] != null) return false;
    frags[index] = Uint8List.fromList(payload);
    _have++;
    return true;
  }

  bool get complete => _have >= frags.length;

  Uint8List assemble() {
    final builder = BytesBuilder(copy: false);
    for (final frag in frags) {
      builder.add(frag!);
    }
    return builder.toBytes();
  }
}
