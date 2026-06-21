import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:universal_ble/universal_ble.dart';

import 'messages.dart';
import 'peer_link.dart';

const bluetoothServiceUuid = '7b3d2f40-5e4f-4a86-b9e8-65e71c2c9001';
const _identityCharacteristicUuid = '7b3d2f41-5e4f-4a86-b9e8-65e71c2c9001';
const _toPeripheralCharacteristicUuid = '7b3d2f42-5e4f-4a86-b9e8-65e71c2c9001';
const _toCentralCharacteristicUuid = '7b3d2f43-5e4f-4a86-b9e8-65e71c2c9001';

class BluetoothIncomingLink {
  BluetoothIncomingLink({
    required this.peerId,
    required this.folderId,
    required this.link,
  });

  final String peerId;
  final String folderId;
  final PeerLink link;
}

class BluetoothTransport {
  BluetoothTransport({required this.deviceId, required this.deviceName});

  final String deviceId;
  final String deviceName;

  final _incoming = StreamController<BluetoothIncomingLink>.broadcast();
  final _peripheralAssemblers = <String, _BleFrameAssembler>{};
  final _peripheralLinks = <String, _PeripheralBleLink>{};
  final _subscriptions = <StreamSubscription<dynamic>>[];

  bool _started = false;
  bool _targetedNotify = false;

  Stream<BluetoothIncomingLink> get incoming => _incoming.stream;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    if (BleCapabilities.requiresRuntimePermission) {
      await UniversalBle.requestPermissions();
    }
    UniversalBle.queueType = QueueType.perDevice;

    if (!BleCapabilities.supportsPeripheralApi) return;

    final availability = await UniversalBlePeripheral.getAvailabilityState();
    if (availability != PeripheralReadinessState.ready) return;

    final capabilities = await UniversalBlePeripheral.getCapabilities();
    if (!capabilities.supportsPeripheralMode) return;
    _targetedNotify = capabilities.supportsTargetedCharacteristicUpdate;

    UniversalBlePeripheral.setReadRequestHandlers(_handleRead);
    UniversalBlePeripheral.setWriteRequestHandlers(_handleWrite);

    await UniversalBlePeripheral.clearServices();
    await UniversalBlePeripheral.addService(
      BlePeripheralService(
        uuid: bluetoothServiceUuid,
        characteristics: [
          BlePeripheralCharacteristic(
            uuid: _identityCharacteristicUuid,
            properties: const [CharacteristicProperty.read],
            permissions: const [PeripheralAttributePermission.readable],
            value: _identityValue(),
          ),
          BlePeripheralCharacteristic(
            uuid: _toPeripheralCharacteristicUuid,
            properties: const [
              CharacteristicProperty.write,
              CharacteristicProperty.writeWithoutResponse,
            ],
            permissions: const [PeripheralAttributePermission.writeable],
          ),
          BlePeripheralCharacteristic(
            uuid: _toCentralCharacteristicUuid,
            properties: const [CharacteristicProperty.notify],
            permissions: const [PeripheralAttributePermission.readable],
            value: Uint8List(0),
          ),
        ],
      ),
      timeout: const Duration(seconds: 10),
    );
    await UniversalBlePeripheral.startAdvertising(
      services: const [bluetoothServiceUuid],
      localName: defaultTargetPlatform == TargetPlatform.windows
          ? null
          : _advertisedName,
      timeout: const Duration(seconds: 10),
    );

    _subscriptions.add(
      UniversalBlePeripheral.connectionStateStream.listen((event) {
        if (!event.connected) _closePeripheralDevice(event.deviceId);
      }),
    );
  }

  Future<PeerLink> open({
    required String peerId,
    required String folderId,
  }) async {
    await start();
    final device = await _findDevice(peerId);
    await UniversalBle.stopScan();
    await UniversalBle.connect(
      device.deviceId,
      timeout: const Duration(seconds: 30),
    );
    try {
      await UniversalBle.requestMtu(device.deviceId, 247).catchError((_) => 23);
      if (BleCapabilities.supportsConnectionPriorityApi) {
        await UniversalBle.requestConnectionPriority(
          device.deviceId,
          BleConnectionPriority.highPerformance,
        ).catchError((_) {});
      }
      await UniversalBle.discoverServices(
        device.deviceId,
        timeout: const Duration(seconds: 15),
      );
      await UniversalBle.subscribeNotifications(
        device.deviceId,
        bluetoothServiceUuid,
        _toCentralCharacteristicUuid,
        timeout: const Duration(seconds: 10),
      );
      final link = _CentralBleLink(device.deviceId, peerId);
      _subscriptions.add(
        UniversalBle.characteristicValueStream(
          device.deviceId,
          _toCentralCharacteristicUuid,
        ).listen(link.addFrame, onDone: link.closeIncoming),
      );
      await link.sendOpen(folderId: folderId, selfDeviceId: deviceId);
      return link;
    } on Object {
      await UniversalBle.disconnect(device.deviceId);
      rethrow;
    }
  }

  PeripheralReadRequestResult? _handleRead(
    String deviceId,
    String characteristicId,
    int offset,
    Uint8List? value,
  ) {
    if (characteristicId != _identityCharacteristicUuid) return null;
    final identity = _identityValue();
    if (offset >= identity.length) {
      return PeripheralReadRequestResult(value: Uint8List(0), offset: offset);
    }
    return PeripheralReadRequestResult(
      value: identity.sublist(offset),
      offset: offset,
    );
  }

  PeripheralWriteRequestResult? _handleWrite(
    String centralDeviceId,
    String characteristicId,
    int offset,
    Uint8List? value,
  ) {
    if (characteristicId != _toPeripheralCharacteristicUuid || value == null) {
      return null;
    }
    final assembler = _peripheralAssemblers[centralDeviceId] ??=
        _BleFrameAssembler();
    final frame = assembler.add(value);
    if (frame == null) return PeripheralWriteRequestResult();

    switch (frame.kind) {
      case _BleFrameKind.open:
        final open = _OpenFrame.decode(frame.payload);
        final key = _peripheralKey(centralDeviceId, open.peerId, open.folderId);
        _peripheralLinks.putIfAbsent(key, () {
          final link = _PeripheralBleLink(
            centralDeviceId: centralDeviceId,
            peerId: open.peerId,
            targetedNotify: _targetedNotify,
          );
          _incoming.add(
            BluetoothIncomingLink(
              peerId: open.peerId,
              folderId: open.folderId,
              link: link,
            ),
          );
          return link;
        });
      case _BleFrameKind.data:
        for (final link in _peripheralLinks.values.where(
          (link) => link.centralDeviceId == centralDeviceId,
        )) {
          link.addMessage(frame.payload);
        }
    }
    return PeripheralWriteRequestResult();
  }

  Future<void> stop() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    for (final link in [..._peripheralLinks.values]) {
      await link.close();
    }
    _peripheralLinks.clear();
    _peripheralAssemblers.clear();
    if (BleCapabilities.supportsPeripheralApi) {
      await UniversalBlePeripheral.stopAdvertising().catchError((_) {});
      await UniversalBlePeripheral.clearServices().catchError((_) {});
    }
    _started = false;
  }

  Future<BleDevice> _findDevice(String peerId) async {
    final completer = Completer<BleDevice>();
    late final StreamSubscription<BleDevice> subscription;
    subscription = UniversalBle.scanStream.listen((device) async {
      if (completer.isCompleted ||
          !device.services.contains(bluetoothServiceUuid)) {
        return;
      }
      try {
        await UniversalBle.stopScan();
        await UniversalBle.connect(
          device.deviceId,
          timeout: const Duration(seconds: 15),
        );
        final identity = _decodeIdentity(
          await UniversalBle.read(
            device.deviceId,
            bluetoothServiceUuid,
            _identityCharacteristicUuid,
            timeout: const Duration(seconds: 10),
          ),
        );
        await UniversalBle.disconnect(device.deviceId);
        if (identity == peerId && !completer.isCompleted) {
          completer.complete(device);
        }
      } on Object {
        await UniversalBle.disconnect(device.deviceId).catchError((_) {});
        if (!completer.isCompleted) {
          await UniversalBle.startScan(
            scanFilter: ScanFilter(withServices: const [bluetoothServiceUuid]),
          ).catchError((_) {});
        }
      }
    });

    await UniversalBle.startScan(
      scanFilter: ScanFilter(withServices: const [bluetoothServiceUuid]),
    );
    try {
      return await completer.future.timeout(const Duration(seconds: 45));
    } finally {
      await subscription.cancel();
      await UniversalBle.stopScan().catchError((_) {});
    }
  }

  Uint8List _identityValue() => Uint8List.fromList(utf8.encode(deviceId));

  String _decodeIdentity(Uint8List bytes) => utf8.decode(bytes);

  String get _advertisedName {
    final prefix = deviceId.length <= 8 ? deviceId : deviceId.substring(0, 8);
    final cleanName = deviceName.replaceAll(RegExp(r'[^ -~]'), '').trim();
    final suffix = cleanName.isEmpty ? prefix : cleanName;
    return 'PM-$prefix-$suffix';
  }

  void _closePeripheralDevice(String centralDeviceId) {
    for (final entry in [..._peripheralLinks.entries]) {
      if (entry.value.centralDeviceId == centralDeviceId) {
        entry.value.closeIncoming();
        _peripheralLinks.remove(entry.key);
      }
    }
    _peripheralAssemblers.remove(centralDeviceId);
  }

  String _peripheralKey(
    String centralDeviceId,
    String peerId,
    String folderId,
  ) => '$centralDeviceId/$peerId/$folderId';
}

class _CentralBleLink implements PeerLink {
  _CentralBleLink(this.deviceId, this.peerId);

  final String deviceId;

  @override
  final String peerId;

  final _incoming = StreamController<SyncMessage>();
  final _assembler = _BleFrameAssembler();

  @override
  Stream<SyncMessage> get incoming => _incoming.stream;

  Future<void> sendOpen({
    required String folderId,
    required String selfDeviceId,
  }) async {
    await _writeFrame(
      _BleFrameKind.open,
      _OpenFrame(peerId: selfDeviceId, folderId: folderId).encode(),
    );
  }

  void addFrame(Uint8List value) {
    final frame = _assembler.add(value);
    if (frame == null || frame.kind != _BleFrameKind.data) return;
    _incoming.add(SyncMessage.decode(frame.payload));
  }

  @override
  Future<void> send(SyncMessage message) async =>
      _writeFrame(_BleFrameKind.data, message.encode());

  Future<void> _writeFrame(_BleFrameKind kind, Uint8List payload) async {
    for (final chunk in _BleFramer.split(kind, payload)) {
      await UniversalBle.write(
        deviceId,
        bluetoothServiceUuid,
        _toPeripheralCharacteristicUuid,
        chunk,
        withoutResponse: false,
        timeout: const Duration(seconds: 10),
      );
    }
  }

  @override
  Future<void> close() async {
    await UniversalBle.unsubscribe(
      deviceId,
      bluetoothServiceUuid,
      _toCentralCharacteristicUuid,
    ).catchError((_) {});
    await UniversalBle.disconnect(deviceId).catchError((_) {});
    await closeIncoming();
  }

  Future<void> closeIncoming() async {
    if (!_incoming.isClosed) await _incoming.close();
  }
}

class _PeripheralBleLink implements PeerLink {
  _PeripheralBleLink({
    required this.centralDeviceId,
    required this.peerId,
    required this.targetedNotify,
  });

  final String centralDeviceId;
  final bool targetedNotify;

  @override
  final String peerId;

  final _incoming = StreamController<SyncMessage>();

  @override
  Stream<SyncMessage> get incoming => _incoming.stream;

  void addMessage(Uint8List value) {
    _incoming.add(SyncMessage.decode(value));
  }

  @override
  Future<void> send(SyncMessage message) async {
    for (final chunk in _BleFramer.split(
      _BleFrameKind.data,
      message.encode(),
    )) {
      await UniversalBlePeripheral.updateCharacteristicValue(
        characteristicId: _toCentralCharacteristicUuid,
        value: chunk,
        deviceId: targetedNotify ? centralDeviceId : null,
      );
    }
  }

  @override
  Future<void> close() async => closeIncoming();

  Future<void> closeIncoming() async {
    if (!_incoming.isClosed) await _incoming.close();
  }
}

enum _BleFrameKind {
  data(0),
  open(1);

  const _BleFrameKind(this.code);
  final int code;

  static _BleFrameKind fromCode(int code) => switch (code) {
    0 => _BleFrameKind.data,
    1 => _BleFrameKind.open,
    _ => throw FormatException('unknown BLE frame kind: $code'),
  };
}

class _BleFrame {
  const _BleFrame(this.kind, this.payload);

  final _BleFrameKind kind;
  final Uint8List payload;
}

class _BleFramer {
  static const maxChunkPayload = 160;

  static Iterable<Uint8List> split(
    _BleFrameKind kind,
    Uint8List payload,
  ) sync* {
    var offset = 0;
    do {
      final end = (offset + maxChunkPayload).clamp(0, payload.length);
      final fin = end == payload.length ? 1 : 0;
      yield Uint8List.fromList([
        kind.code,
        fin,
        ...payload.sublist(offset, end),
      ]);
      offset = end;
    } while (offset < payload.length);
  }
}

class _BleFrameAssembler {
  _BleFrameKind? _kind;
  final _buffer = BytesBuilder(copy: false);

  _BleFrame? add(Uint8List chunk) {
    if (chunk.length < 2) throw const FormatException('short BLE frame');
    final kind = _BleFrameKind.fromCode(chunk[0]);
    _kind ??= kind;
    if (_kind != kind) throw const FormatException('interleaved BLE frame');
    _buffer.add(chunk.sublist(2));
    if (chunk[1] == 0) return null;
    final frame = _BleFrame(kind, _buffer.takeBytes());
    _kind = null;
    return frame;
  }
}

class _OpenFrame {
  const _OpenFrame({required this.peerId, required this.folderId});

  final String peerId;
  final String folderId;

  Uint8List encode() => Uint8List.fromList(
    utf8.encode(jsonEncode({'peerId': peerId, 'folderId': folderId})),
  );

  static _OpenFrame decode(Uint8List bytes) {
    final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    return _OpenFrame(
      peerId: json['peerId'] as String,
      folderId: json['folderId'] as String,
    );
  }
}
