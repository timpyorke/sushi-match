import 'package:flutter_test/flutter_test.dart';
import 'package:sushi_trio/services/audio.dart';
import 'package:sushi_trio/services/restaurant.dart';
import 'package:sushi_trio/ui/l10n.dart';
import 'package:sushi_trio/ui/map/japan_map.dart';

/// Guards the "add a level / restaurant" checklist in docs/adding-levels.md:
/// whatever a new restaurant needs, one of these fails until it is there.
void main() {
  tearDown(() => L10n.language = 'en');

  test('restaurants cover levels 1..N contiguously', () {
    var next = 1;
    for (final s in Restaurant.shops) {
      expect(s.firstLevel, next, reason: s.id);
      expect(s.lastLevel, greaterThanOrEqualTo(s.firstLevel), reason: s.id);
      next = s.lastLevel + 1;
    }
    expect(Restaurant.totalLevels, next - 1);
  });

  test('every furniture piece has a name in every language', () {
    for (final f in Restaurant.furniture) {
      for (final lang in L10n.languages.keys) {
        L10n.language = lang;
        expect(L10n.t(f.nameKey), isNot(f.nameKey), reason: '$lang ${f.id}');
      }
    }
  });

  test('every restaurant has map art, music and text', () {
    for (final s in Restaurant.shops) {
      expect(kMapRegions, contains(s.id), reason: '${s.id} map region');
      expect(Audio.tracks, contains(Audio.trackFor(s.id)),
          reason: '${s.id} music');
      for (final lang in L10n.languages.keys) {
        L10n.language = lang;
        for (final key in [s.nameKey, 'zone_${s.id}']) {
          expect(L10n.t(key), isNot(key), reason: '$lang $key');
        }
      }
    }
  });
}
