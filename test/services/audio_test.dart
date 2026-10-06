import 'package:flutter_test/flutter_test.dart';
import 'package:sushi_trio/services/audio.dart';

void main() {
  test('match pitch climbs with cascade depth and tops out', () {
    expect(Sfx.forCascade(1), Sfx.match1);
    expect(Sfx.forCascade(3), Sfx.match3);
    expect(Sfx.forCascade(6), Sfx.match6);
    expect(Sfx.forCascade(20), Sfx.match6);
    expect(Sfx.forCascade(0), Sfx.match1);
  });

  test('playing before init is a silent no-op', () {
    expect(() => Audio.play(Sfx.win), returnsNormally);
    expect(Audio.startMusic, returnsNormally);
    expect(Audio.stopMusic, returnsNormally);
  });
}
