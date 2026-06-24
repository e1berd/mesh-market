import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'port_mapping.dart';

const _ssdpAddress = '239.255.255.250';
const _ssdpPort = 1900;
const _description = 'mesh-market';

const _serviceTypes = [
  'urn:schemas-upnp-org:service:WANIPConnection:1',
  'urn:schemas-upnp-org:service:WANPPPConnection:1',
];

class UpnpIgdClient implements PortMapBackend {
  _Igd? _igd;

  @override
  String get name => 'UPnP-IGD';

  @override
  Future<PortMapping?> request({
    required int internalPort,
    required MapProtocol protocol,
    required Duration lifetime,
  }) async {
    final igd = await _resolve();
    if (igd == null) return null;
    final proto = protocol == MapProtocol.tcp ? 'TCP' : 'UDP';
    final ok = await _soap(igd, 'AddPortMapping', {
      'NewRemoteHost': '',
      'NewExternalPort': '$internalPort',
      'NewProtocol': proto,
      'NewInternalPort': '$internalPort',
      'NewInternalClient': igd.internalClient,
      'NewEnabled': '1',
      'NewPortMappingDescription': _description,
      'NewLeaseDuration': '${lifetime.inSeconds}',
    });
    if (ok == null) return null;
    final external = await _externalAddress(igd);
    return PortMapping(
      protocol: protocol,
      internalPort: internalPort,
      externalPort: internalPort,
      externalAddress: external,
      lifetime: lifetime,
      via: name,
    );
  }

  @override
  Future<void> release(PortMapping mapping) async {
    final igd = await _resolve();
    if (igd == null) return;
    await _soap(igd, 'DeletePortMapping', {
      'NewRemoteHost': '',
      'NewExternalPort': '${mapping.externalPort}',
      'NewProtocol': mapping.protocol == MapProtocol.tcp ? 'TCP' : 'UDP',
    });
  }

  Future<InternetAddress?> _externalAddress(_Igd igd) async {
    final body = await _soap(igd, 'GetExternalIPAddress', const {});
    final raw = body == null ? null : _tag(body, 'NewExternalIPAddress');
    return raw == null ? null : InternetAddress.tryParse(raw);
  }

  Future<_Igd?> _resolve() async {
    if (_igd != null) return _igd;
    final location = await _discover();
    if (location == null) return null;
    return _igd = await _describe(location);
  }

  Future<Uri?> _discover() async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    final completer = Completer<Uri?>();
    late StreamSubscription<RawSocketEvent> sub;
    sub = socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      final datagram = socket.receive();
      if (datagram == null) return;
      final text = utf8.decode(datagram.data, allowMalformed: true);
      final location = _header(text, 'location');
      if (location == null) return;
      final uri = Uri.tryParse(location);
      if (uri != null && !completer.isCompleted) completer.complete(uri);
    });
    for (final target in _serviceTypes.followedBy(const [
      'urn:schemas-upnp-org:device:InternetGatewayDevice:1',
    ])) {
      socket.send(
        utf8.encode(_searchRequest(target)),
        InternetAddress(_ssdpAddress),
        _ssdpPort,
      );
    }
    try {
      return await completer.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () => null,
      );
    } finally {
      await sub.cancel();
      socket.close();
    }
  }

  Future<_Igd?> _describe(Uri location) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(location);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final serviceType = _serviceTypes.firstWhere(
        body.contains,
        orElse: () => '',
      );
      if (serviceType.isEmpty) return null;
      final controlPath = _controlUrlFor(body, serviceType);
      if (controlPath == null) return null;
      final base = Uri.tryParse(_tag(body, 'URLBase') ?? '') ?? location;
      final controlUrl = base.resolve(controlPath);
      final internalClient = await _localClient(controlUrl.host);
      if (internalClient == null) return null;
      return _Igd(
        controlUrl: controlUrl,
        serviceType: serviceType,
        internalClient: internalClient,
      );
    } on Object {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  Future<String?> _soap(
    _Igd igd,
    String action,
    Map<String, String> args,
  ) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(igd.controlUrl);
      request.headers
        ..set(HttpHeaders.contentTypeHeader, 'text/xml; charset="utf-8"')
        ..set('SOAPAction', '"${igd.serviceType}#$action"');
      request.write(_envelope(igd.serviceType, action, args));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != 200) return null;
      return body;
    } on Object {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  Future<String?> _localClient(String host) async {
    final device = InternetAddress.tryParse(host);
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    final prefix = device?.address.substring(
      0,
      device.address.lastIndexOf('.') + 1,
    );
    String? fallback;
    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        fallback ??= address.address;
        if (prefix != null && address.address.startsWith(prefix)) {
          return address.address;
        }
      }
    }
    return fallback;
  }

  String _searchRequest(String target) =>
      'M-SEARCH * HTTP/1.1\r\n'
      'HOST: $_ssdpAddress:$_ssdpPort\r\n'
      'MAN: "ssdp:discover"\r\n'
      'MX: 2\r\n'
      'ST: $target\r\n\r\n';

  String _envelope(String serviceType, String action, Map<String, String> args) {
    final body = args.entries
        .map((entry) => '<${entry.key}>${entry.value}</${entry.key}>')
        .join();
    return '<?xml version="1.0"?>'
        '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" '
        's:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">'
        '<s:Body><u:$action xmlns:u="$serviceType">$body'
        '</u:$action></s:Body></s:Envelope>';
  }

  String? _controlUrlFor(String description, String serviceType) {
    final marker = description.indexOf(serviceType);
    if (marker < 0) return null;
    final tail = description.substring(marker);
    return _tag(tail, 'controlURL');
  }

  String? _tag(String source, String tag) {
    final open = source.indexOf('<$tag>');
    if (open < 0) return null;
    final close = source.indexOf('</$tag>', open);
    if (close < 0) return null;
    return source.substring(open + tag.length + 2, close).trim();
  }

  String? _header(String response, String key) {
    for (final line in const LineSplitter().convert(response)) {
      final colon = line.indexOf(':');
      if (colon < 0) continue;
      if (line.substring(0, colon).trim().toLowerCase() == key) {
        return line.substring(colon + 1).trim();
      }
    }
    return null;
  }
}

class _Igd {
  const _Igd({
    required this.controlUrl,
    required this.serviceType,
    required this.internalClient,
  });

  final Uri controlUrl;
  final String serviceType;
  final String internalClient;
}
