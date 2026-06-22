const _adjectives = [
  'Amber', 'Brave', 'Calm', 'Clever', 'Cosmic', 'Crimson', 'Dusty', 'Eager',
  'Electric', 'Emerald', 'Frosty', 'Gentle', 'Golden', 'Happy', 'Hidden',
  'Indigo', 'Jolly', 'Lively', 'Lucky', 'Lunar', 'Mellow', 'Mighty', 'Misty',
  'Nimble', 'Noble', 'Quiet', 'Rapid', 'Royal', 'Rustic', 'Scarlet', 'Silent',
  'Silver', 'Solar', 'Sunny', 'Swift', 'Teal', 'Vivid', 'Witty', 'Zesty',
];

const _nouns = [
  'Otter', 'Falcon', 'Maple', 'Comet', 'Harbor', 'Lynx', 'Willow', 'Raven',
  'Cedar', 'Heron', 'Boulder', 'Meadow', 'Beacon', 'Canyon', 'Glacier',
  'Lantern', 'Marble', 'Nimbus', 'Orchid', 'Pebble', 'Quartz', 'River',
  'Summit', 'Thicket', 'Tundra', 'Vortex', 'Walrus', 'Anchor', 'Basalt',
  'Cobalt', 'Delta', 'Ember', 'Fjord', 'Grove', 'Harbor', 'Isle', 'Juniper',
];

String randomDeviceName(String seed) {
  var hash = 0x811c9dc5;
  for (final unit in seed.codeUnits) {
    hash = (hash ^ unit) * 0x01000193 & 0xffffffff;
  }
  final adjective = _adjectives[hash % _adjectives.length];
  final noun = _nouns[(hash ~/ _adjectives.length) % _nouns.length];
  return '$adjective $noun';
}
