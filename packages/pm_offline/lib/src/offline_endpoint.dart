class OfflineEndpoint {
  const OfflineEndpoint({required this.host, required this.port});

  final String host;
  final int port;

  static OfflineEndpoint? fromMap(Map<Object?, Object?>? map) {
    if (map == null) return null;
    final host = map['host'] as String?;
    final port = map['port'] as int?;
    if (host == null || port == null) return null;
    return OfflineEndpoint(host: host, port: port);
  }
}
