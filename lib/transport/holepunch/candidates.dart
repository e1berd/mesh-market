import 'dart:io';

class PunchCandidate {
  const PunchCandidate(this.address, this.port);

  final InternetAddress address;
  final int port;

  String encode() => '${address.address}|$port';

  static PunchCandidate? decode(String value) {
    final split = value.lastIndexOf('|');
    if (split <= 0) return null;
    final address = InternetAddress.tryParse(value.substring(0, split));
    final port = int.tryParse(value.substring(split + 1));
    if (address == null || port == null) return null;
    return PunchCandidate(address, port);
  }

  @override
  bool operator ==(Object other) =>
      other is PunchCandidate &&
      other.address.address == address.address &&
      other.port == port;

  @override
  int get hashCode => Object.hash(address.address, port);
}

Future<List<PunchCandidate>> localCandidates(
  int port, {
  PunchCandidate? mapped,
}) async {
  final candidates = <PunchCandidate>[];
  final seen = <String>{};
  void add(PunchCandidate candidate) {
    if (seen.add(candidate.encode())) candidates.add(candidate);
  }

  if (mapped != null) add(mapped);
  final interfaces = await NetworkInterface.list(
    type: InternetAddressType.IPv4,
    includeLoopback: false,
  );
  for (final interface in interfaces) {
    for (final address in interface.addresses) {
      add(PunchCandidate(address, port));
    }
  }
  return candidates;
}
