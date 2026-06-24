import 'dart:async';

import 'gateway.dart';
import 'nat_pmp.dart';
import 'pcp.dart';
import 'port_mapping.dart';
import 'upnp.dart';

const _defaultLifetime = Duration(hours: 2);

class PortMapper {
  PortMapper({
    required this.internalPort,
    this.protocol = MapProtocol.tcp,
    this.lifetime = _defaultLifetime,
  });

  final int internalPort;
  final MapProtocol protocol;
  final Duration lifetime;

  final _controller = StreamController<PortMapping?>.broadcast();
  final _upnp = UpnpIgdClient();
  Timer? _refresh;
  bool _running = false;
  _Lease? _lease;

  Stream<PortMapping?> get mappings => _controller.stream;
  PortMapping? get current => _lease?.mapping;

  Future<PortMapping?> start() async {
    if (_running) return current;
    _running = true;
    final mapping = await _acquire();
    if (mapping != null) _scheduleRefresh(mapping.lifetime);
    return mapping;
  }

  Future<void> stop() async {
    _running = false;
    _refresh?.cancel();
    _refresh = null;
    final lease = _lease;
    _lease = null;
    if (lease != null) {
      try {
        await lease.backend.release(lease.mapping);
      } on Object {
        // gateway may already have dropped the lease
      }
    }
    if (!_controller.isClosed) _controller.add(null);
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }

  Future<PortMapping?> _acquire() async {
    final routes = await gatewayRoutes();
    for (final route in routes) {
      for (final backend in <PortMapBackend>[
        PcpClient(route),
        NatPmpClient(route),
      ]) {
        final mapping = await _tryBackend(backend);
        if (mapping != null) return mapping;
      }
    }
    final viaUpnp = await _tryBackend(_upnp);
    if (viaUpnp != null) return viaUpnp;
    if (!_controller.isClosed) _controller.add(null);
    return null;
  }

  Future<PortMapping?> _tryBackend(PortMapBackend backend) async {
    try {
      final mapping = await backend.request(
        internalPort: internalPort,
        protocol: protocol,
        lifetime: lifetime,
      );
      if (mapping == null) return null;
      _lease = _Lease(backend: backend, mapping: mapping);
      if (!_controller.isClosed) _controller.add(mapping);
      return mapping;
    } on Object {
      return null;
    }
  }

  void _scheduleRefresh(Duration granted) {
    _refresh?.cancel();
    final half = granted.inSeconds <= 0
        ? lifetime ~/ 2
        : Duration(seconds: granted.inSeconds ~/ 2);
    final delay = half < const Duration(seconds: 30)
        ? const Duration(seconds: 30)
        : half;
    _refresh = Timer(delay, () async {
      if (!_running) return;
      final mapping = await _acquire();
      if (mapping != null) _scheduleRefresh(mapping.lifetime);
    });
  }
}

class _Lease {
  const _Lease({required this.backend, required this.mapping});

  final PortMapBackend backend;
  final PortMapping mapping;
}
