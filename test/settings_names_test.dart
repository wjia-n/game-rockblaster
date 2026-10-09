import 'package:flutter_test/flutter_test.dart';
import 'package:rockblaster/services/settings_service.dart';

void main() {
  test('profile JSON round-trips and cleans names', () {
    // Current order-safe format: a single JSON string with a names list.
    expect(BlastSettings.decodeProfile('{"names":["  Nova  "]}', null),
        'Nova');
    // Legacy {"name": ...} format still migrates.
    expect(BlastSettings.decodeProfile('{"name":"  Vega  "}', null), 'Vega');
    // Legacy plain-string key still migrates.
    expect(BlastSettings.decodeProfile(null, '  Rigel '), 'Rigel');
    // Null / corrupt / empty data falls back to the default.
    expect(BlastSettings.decodeProfile(null, null),
        BlastSettings.defaultName);
    expect(BlastSettings.decodeProfile('not json', null),
        BlastSettings.defaultName);
    expect(BlastSettings.decodeProfile('{"names":[]}', null),
        BlastSettings.defaultName);
    expect(BlastSettings.decodeProfile('{"names":[""]}', null),
        BlastSettings.defaultName);
    // Encoder produces a single JSON string (never a StringList).
    final encoded = BlastSettings.encodeProfile('Nova');
    expect(encoded, contains('Nova'));
    expect(encoded, contains('names'));
    expect(BlastSettings.decodeProfile(encoded, null), 'Nova');
    // Blank names become the default.
    expect(BlastSettings.decodeProfile(
        BlastSettings.encodeProfile('   '), null),
        BlastSettings.defaultName);
  });
}
