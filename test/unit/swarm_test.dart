import 'package:point_machine/transport/swarm.dart';
import 'package:test/test.dart';

void main() {
  test('infohash is deterministic and 40 hex chars', () async {
    final secret = [1, 2, 3, 4, 5];
    final first = await infohashFor(secret);
    expect(first, equals(await infohashFor(secret)));
    expect(first.length, equals(40));
    expect(await infohashFor([9, 9]), isNot(equals(first)));
  });

  test('new swarm secret is 32 unpredictable bytes', () {
    final secret = newSwarmSecret();
    expect(secret.length, equals(32));
    expect(newSwarmSecret(), isNot(equals(secret)));
  });
}
