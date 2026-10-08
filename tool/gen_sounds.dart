// ignore_for_file: avoid_print
// Synthesises the sound effects and BGM into assets/audio/ as 44.1 kHz 16-bit
// mono WAV (marimba and bell tones, filtered noise, a reverb tail, soft pad and
// taiko under the koto line), which tool/to_m4a.sh then turns into the .m4a files the game
// bundles. Swap any file for real audio of the same name later; the game only
// refers to the file names (see lib/services/audio.dart).
//
//   dart run tool/gen_sounds.dart && tool/to_m4a.sh
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

part 'sounds/dsp.dart';

const _sr = 44100;
final _rng = Random(7);

// C major pentatonic ladder for cascades: C5 D5 E5 G5 A5 C6.
const _ladder = [523.25, 587.33, 659.25, 783.99, 880.0, 1046.5];

Map<String, Float64List> _sfx() {
  final out = <String, Float64List>{};

  // A soft whoosh of band-passed air for a swap.
  out['swap'] = () {
    final air = _lp(_bp(_noise(0.14, decay: 14), 1400, 1.0), 2800);
    return _mix2(air, _sweep(330, 520, 0.1, decay: 20), 0.4);
  }();
  out['invalid'] = () {
    final b = _buf(0.32);
    _mix(b, _marimba(196, 0.12, decay: 14), 0);
    _mix(b, _marimba(165, 0.16, decay: 12), 0.11);
    return _lp(b, 1800);
  }();

  // Each cascade step is a marimba note with a glassy bell on top; the pitch
  // climbs so a combo is audible.
  for (var i = 0; i < _ladder.length; i++) {
    final b = _buf(0.45);
    _mix(b, _marimba(_ladder[i], 0.45, decay: 8), 0);
    _mix(b, _bell(_ladder[i] * 2, 0.35, decay: 9), 0, 0.3);
    out['match_${i + 1}'] = _room(b, mix: 0.1, tail: 0.1);
  }

  out['special'] = _room(
      _seq([
        for (var i = 0; i < 6; i++) (_ladder[min(i, 5)] * 1.5, i * 0.05),
      ], 0.9, dur: 0.6, decay: 5),
      mix: 0.25,
      tail: 0.3);

  out['boom'] = () {
    final b = _buf(0.8);
    _mix(b, _lp(_noise(0.8, decay: 4.5), 600), 0);
    _mix(b, _sweep(95, 32, 0.7, decay: 4), 0, 1.5);
    _mix(b, _hp(_noise(0.08, decay: 40), 1500), 0, 0.3);
    return _room(b, mix: 0.2, tail: 0.3);
  }();

  // Ice crack: a bright snap, then a few little ticks.
  out['crack'] = () {
    final b = _buf(0.3);
    _mix(b, _bp(_noise(0.1, decay: 35), 2800, 1.5), 0, 0.8);
    _mix(b, _sweep(1400, 700, 0.06, decay: 50), 0, 0.4);
    for (final at in const [0.07, 0.12, 0.17]) {
      _mix(b, _bp(_noise(0.03, decay: 100), 3800, 2), at, 0.25);
    }
    return _lp(b, 5000);
  }();

  out['chime'] = _room(
      _seq([(1318.5, 0), (1760, 0.1), (2093, 0.2)], 0.9, dur: 0.7, decay: 4),
      mix: 0.3,
      tail: 0.4);
  out['unlock'] = _room(
      _seq([(784, 0), (988, 0.08), (1318.5, 0.16), (1568, 0.24)], 0.9,
          dur: 0.6, decay: 5),
      mix: 0.3,
      tail: 0.4);

  // Meow: a sawtooth with vibrato through two vowel formants.
  out['meow'] = () {
    const dur = 0.5;
    final src = _buf(dur);
    var ph = 0.0;
    for (var i = 0; i < src.length; i++) {
      final t = i / _sr;
      final f = 430 +
          330 * sin(pi * min(1, t / 0.3)) -
          60 * (t / dur) +
          6 * sin(2 * pi * 6 * t);
      ph += f / _sr;
      src[i] = (2 * (ph % 1) - 1) *
          _env(t, dur, 1.5, 0.03) *
          sin(pi * (t / dur).clamp(0, 1));
    }
    final sound = _mix2(_bp(src, 850, 4), _bp(src, 2200, 5), 0.7);
    return _mix2(sound, src, 0.08);
  }();

  out['shuffle'] = () {
    final b = _buf(0.6);
    for (var i = 0; i < 7; i++) {
      _mix(b, _bp(_noise(0.09, decay: 22), 1500 + 150.0 * (i % 3), 1),
          i * 0.065, 0.7 + 0.05 * (i % 2));
    }
    return _lp(b, 3500);
  }();

  // A small wooden knock.
  out['tap'] = () {
    final b = _buf(0.09);
    _mix(b, _marimba(520, 0.09, decay: 45), 0);
    return b;
  }();
  out['coin'] = _room(
      _seq([(1318.5, 0), (1975.5, 0.07)], 0.6, dur: 0.5, decay: 7),
      mix: 0.2,
      tail: 0.25);

  out['win'] = _room(
      _mix2(
          _seq([
            (523.25, 0),
            (659.25, 0.13),
            (783.99, 0.26),
            (1046.5, 0.39),
            (783.99, 0.6),
            (1046.5, 0.72),
            (1318.5, 0.84),
          ], 2.2, dur: 1.2, decay: 3.2, wood: true),
          _seq([(1046.5, 0.84), (1568, 0.84), (2093, 0.84)], 2.2,
              dur: 1.2, decay: 2.5),
          0.35),
      mix: 0.3,
      tail: 0.6);
  out['lose'] = _room(
      _seq([
        (392, 0),
        (349.23, 0.28),
        (311.13, 0.56),
        (261.63, 0.9),
      ], 2.2, dur: 1.0, decay: 3.2, wood: true),
      mix: 0.3,
      tail: 0.6);

  return out;
}

/// One loop per restaurant: a plucked Hirajoshi (A B C E F) line over a warm
/// pad, a round bass and light taiko / shaker, 8 bars. [bpm] sets the pace,
/// [shift] moves the key (frequency ratio), [variant] picks the tune.
Float64List _bgm({required int bpm, double shift = 1, int variant = 0}) {
  final eighth = 60 / bpm / 2;
  const bars = 8;
  final bar = 8 * eighth;
  final out = _buf(bars * bar);

  const a = [5, -1, 7, -1, 8, -1, 7, 6, 5, -1, 3, -1, 5, -1, -1, -1];
  const b = [8, -1, 9, -1, 8, -1, 7, -1, 6, -1, 5, -1, 3, -1, -1, -1];
  const b2 = [8, -1, 9, -1, 8, -1, 7, -1, 6, -1, 5, -1, 5, -1, -1, -1];
  const c = [3, -1, 5, 6, 7, -1, 5, -1, 8, -1, 7, -1, 6, 5, 3, -1];
  const d = [10, -1, 8, -1, 7, -1, 8, 7, 6, -1, 5, -1, 5, -1, -1, -1];
  const scale = [
    220.0, 246.94, 261.63, 329.63, 349.23, // A3 B3 C4 E4 F4
    440.0, 493.88, 523.25, 659.25, 698.46, 880.0, // A4 B4 C5 E5 F5 A5
  ];
  final melody = switch (variant) {
    1 => [...c, ...b, ...c, ...b2],
    2 => [...a, ...d, ...c, ...b2],
    _ => [...a, ...b, ...a, ...b2],
  };

  // Chords per bar: Am F Am F Am F Am E.
  const am = [220.0, 261.63, 329.63], f = [174.61, 220.0, 261.63];
  const e = [164.81, 246.94, 329.63];
  const roots = [110.0, 87.31, 110.0, 87.31, 110.0, 87.31, 110.0, 82.41];
  const chords = [am, f, am, f, am, f, am, e];

  final pad = _buf(bars * bar), bass = _buf(bars * bar);
  final beats = _buf(bars * bar), tune = _buf(bars * bar);

  for (var i = 0; i < melody.length; i++) {
    if (melody[i] < 0) continue;
    final note = scale[melody[i]] * shift;
    // A little human timing (never early, so the loop seam stays clean) and level, and a faint octave shimmer.
    final at = i * eighth + _rng.nextDouble() * 0.008;
    final gain = 0.8 + _rng.nextDouble() * 0.3;
    _mix(tune, _pluck(note, 1.6), at, gain);
    _mix(tune, _bell(note * 2, 0.5, decay: 9), at, 0.05 * gain);
  }
  for (var i = 0; i < bars; i++) {
    for (final n in chords[i]) {
      _mix(pad, _pad(n * shift, bar * 1.15), i * bar, 0.5);
    }
    final root = roots[i] * shift;
    _mix(bass, _lp(_pluck(root, bar * 0.6, damp: 0.998), 400), i * bar, 1);
    _mix(bass, _lp(_pluck(root * 1.5, 0.9, damp: 0.998), 500),
        i * bar + 4 * eighth, 0.5);
    _mix(beats, _thump(), i * bar, 0.5);
    _mix(beats, _thump(dur: 0.3), i * bar + 4 * eighth, 0.25);
    for (var s = 0; s < 8; s++) {
      _mix(beats, _lp(_hp(_noise(0.05, decay: 60), 5000), 9000),
          i * bar + s * eighth, s.isOdd ? 0.04 : 0.02);
    }
    _mix(beats, _marimba(900 * shift, 0.1, decay: 30), i * bar + 6 * eighth,
        0.06);
  }
  for (var i = 0; i < out.length; i++) {
    out[i] = tune[i] * 0.7 + pad[i] * 0.14 + bass[i] * 0.22 + beats[i] * 0.3;
  }
  return _roomLoop(out);
}

void main() {
  final dir = Directory('assets/audio')..createSync(recursive: true);
  for (final e in _sfx().entries) {
    File('${dir.path}/${e.key}.wav').writeAsBytesSync(_wav(e.value));
  }
  final tracks = {
    'tsukiji': _bgm(bpm: 96),
    'osaka': _bgm(bpm: 112, shift: 1.122, variant: 1),
    'kyoto': _bgm(bpm: 80, shift: 0.891, variant: 2),
    'hokkaido': _bgm(bpm: 104, shift: 1.335, variant: 1),
  };
  for (final e in tracks.entries) {
    File('${dir.path}/bgm_${e.key}.wav')
        .writeAsBytesSync(_wav(e.value, peak: 0.6, fade: false));
  }
  for (final f in dir.listSync().whereType<File>().toList()
    ..sort((x, y) => x.path.compareTo(y.path))) {
    print('${f.path}  ${(f.lengthSync() / 1024).round()} KB');
  }
}
