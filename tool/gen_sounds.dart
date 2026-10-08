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

const _sr = 44100;
final _rng = Random(7);

Float64List _buf(double seconds) => Float64List((seconds * _sr).round());

/// Adds [src] into [dst] starting at [at] seconds, wrapping at the end so a
/// loop tail folds back onto the start.
void _mix(Float64List dst, Float64List src, double at, [double gain = 1]) {
  final start = (at * _sr).round();
  for (var i = 0; i < src.length; i++) {
    dst[(start + i) % dst.length] += src[i] * gain;
  }
}

/// Fast attack, exponential decay, and a short release so nothing clicks.
double _env(double t, double dur, double decay, [double attack = 0.004]) =>
    exp(-decay * t) * min(1, t / attack) * min(1, (dur - t) / 0.01);

// ---------------------------------------------------------------- filters

/// One-pole low-pass at [hz].
Float64List _lp(Float64List x, double hz) {
  final a = 1 - exp(-2 * pi * hz / _sr);
  final y = Float64List(x.length);
  var s = 0.0;
  for (var i = 0; i < x.length; i++) {
    s += (x[i] - s) * a;
    y[i] = s;
  }
  return y;
}

/// x minus its low-pass: a gentle high-pass.
Float64List _hp(Float64List x, double hz) {
  final l = _lp(x, hz);
  return Float64List.fromList([for (var i = 0; i < x.length; i++) x[i] - l[i]]);
}

/// Constant-gain band-pass biquad centred on [hz].
Float64List _bp(Float64List x, double hz, double q) {
  final w = 2 * pi * hz / _sr;
  final alpha = sin(w) / (2 * q);
  final a0 = 1 + alpha, a1 = -2 * cos(w) / a0, a2 = (1 - alpha) / a0;
  final b0 = alpha / a0, b2 = -alpha / a0;
  final y = Float64List(x.length);
  var x1 = 0.0, x2 = 0.0, y1 = 0.0, y2 = 0.0;
  for (var i = 0; i < x.length; i++) {
    final v = b0 * x[i] + b2 * x2 - a1 * y1 - a2 * y2;
    x2 = x1;
    x1 = x[i];
    y2 = y1;
    y1 = v;
    y[i] = v;
  }
  return y;
}

/// Schroeder reverb: four damped combs into two all-passes.
Float64List _reverbTail(Float64List x, {double feedback = 0.8}) {
  final n = x.length;
  final wet = Float64List(n);
  for (final ms in const [29.7, 37.1, 41.1, 43.7]) {
    final d = (ms * _sr / 1000).round();
    final line = Float64List(d);
    var damp = 0.0, p = 0;
    for (var i = 0; i < n; i++) {
      final out = line[p];
      damp += (out - damp) * 0.35;
      line[p] = x[i] + damp * feedback;
      p = (p + 1) % d;
      wet[i] += out * 0.25;
    }
  }
  for (final (ms, g) in const [(5.0, 0.5), (1.7, 0.5)]) {
    final d = (ms * _sr / 1000).round();
    final line = Float64List(d);
    var p = 0;
    for (var i = 0; i < n; i++) {
      final delayed = line[p];
      final v = wet[i] + delayed * g;
      line[p] = v;
      wet[i] = delayed - v * g;
      p = (p + 1) % d;
    }
  }
  return wet;
}

/// Dry signal plus a reverb tail of the given [mix].
Float64List _room(Float64List dry,
    {double mix = 0.2, double tail = 0.4, double feedback = 0.8}) {
  final padded = Float64List(dry.length + (tail * _sr).round())
    ..setRange(0, dry.length, dry);
  final wet = _reverbTail(padded, feedback: feedback);
  for (var i = 0; i < padded.length; i++) {
    padded[i] += wet[i] * mix;
  }
  return padded;
}

/// Reverb for a loop: render the loop twice and keep the second pass, so the
/// tail of the last bar rings into the first and the seam is inaudible.
Float64List _roomLoop(Float64List dry, {double mix = 0.25}) {
  final twice = Float64List(dry.length * 2)
    ..setRange(0, dry.length, dry)
    ..setRange(dry.length, dry.length * 2, dry);
  final wet = _reverbTail(twice, feedback: 0.84);
  return Float64List.fromList([
    for (var i = 0; i < dry.length; i++) dry[i] + wet[dry.length + i] * mix
  ]);
}

// ----------------------------------------------------------------- voices

/// Struck glass / bell: inharmonic partials, the high ones dying first.
Float64List _bell(double freq, double dur, {double decay = 6}) {
  final b = _buf(dur);
  const partials = [(1.0, 1.0, 1.0), (2.76, 0.32, 2.2), (5.4, 0.14, 4.0)];
  for (var i = 0; i < b.length; i++) {
    final t = i / _sr;
    var v = 0.0;
    for (final (ratio, amp, fall) in partials) {
      v += amp * sin(2 * pi * freq * ratio * t) * exp(-decay * fall * t);
    }
    b[i] = v / 1.46 * min(1, t / 0.002) * min(1, (dur - t) / 0.01);
  }
  return b;
}

/// Wooden mallet: a warm fundamental with a quick, bright 4th-partial knock.
Float64List _marimba(double freq, double dur, {double decay = 7}) {
  final b = _buf(dur);
  for (var i = 0; i < b.length; i++) {
    final t = i / _sr;
    b[i] = _env(t, dur, 1, 0.003) *
        (sin(2 * pi * freq * t) * exp(-decay * t) +
            0.45 * sin(2 * pi * freq * 4 * t) * exp(-decay * 5 * t) +
            0.15 * sin(2 * pi * freq * 9.2 * t) * exp(-decay * 12 * t)) /
        1.6;
  }
  return b;
}

/// A tone that glides from [f0] to [f1]; [square] adds a buzzy edge.
Float64List _sweep(double f0, double f1, double dur,
    {double decay = 3, double square = 0}) {
  final b = _buf(dur);
  var phase = 0.0;
  for (var i = 0; i < b.length; i++) {
    final t = i / _sr;
    final f = f0 + (f1 - f0) * (t / dur);
    phase += 2 * pi * f / _sr;
    final s = sin(phase);
    final w = s + square * (s >= 0 ? 1 : -1);
    b[i] = w / (1 + square) * _env(t, dur, decay, 0.003);
  }
  return b;
}

/// White noise with an exponential decay.
Float64List _noise(double dur, {double decay = 8}) {
  final b = _buf(dur);
  for (var i = 0; i < b.length; i++) {
    final t = i / _sr;
    b[i] = (_rng.nextDouble() * 2 - 1) * _env(t, dur, decay, 0.001);
  }
  return b;
}

/// Karplus-Strong plucked string, softened: the koto / shamisen stand-in.
Float64List _pluck(double freq, double dur, {double damp = 0.996}) {
  final n = max(2, (_sr / freq).round());
  final line = Float64List(n);
  for (var i = 0; i < n; i++) {
    line[i] = _rng.nextDouble() * 2 - 1;
  }
  // Smooth the excitation so the attack is a soft pluck, not a burst of hiss.
  for (var pass = 0; pass < 2; pass++) {
    var prev = line[n - 1];
    for (var i = 0; i < n; i++) {
      final cur = line[i];
      line[i] = (prev + cur) * 0.5;
      prev = cur;
    }
  }
  final b = _buf(dur);
  var p = 0;
  for (var i = 0; i < b.length; i++) {
    final cur = line[p];
    final next = line[(p + 1) % n];
    line[p] = (cur + next) * 0.5 * damp;
    b[i] = cur * min(1, (dur - i / _sr) / 0.05);
    p = (p + 1) % n;
  }
  return _lp(b, 3200);
}

/// Warm pad: three slightly detuned triangles, slow swell, low-passed.
Float64List _pad(double freq, double dur) {
  final b = _buf(dur);
  for (var i = 0; i < b.length; i++) {
    final t = i / _sr;
    var v = 0.0;
    for (final detune in const [0.997, 1.0, 1.003]) {
      final ph = (freq * detune * t) % 1;
      v += 4 * (ph - 0.5).abs() - 1;
    }
    final swell = pow(sin(pi * (t / dur).clamp(0, 1)), 0.6);
    b[i] = v / 3 * swell;
  }
  return _lp(b, 900);
}

/// Taiko-like thump: a pitch-dropping sine plus a little skin noise.
Float64List _thump({double dur = 0.45}) {
  final b = _buf(dur);
  var ph = 0.0;
  for (var i = 0; i < b.length; i++) {
    final t = i / _sr;
    ph += 2 * pi * (48 + 70 * exp(-18 * t)) / _sr;
    b[i] = sin(ph) * _env(t, dur, 7, 0.002);
  }
  return _mix2(b, _lp(_noise(dur, decay: 40), 700), 0.25);
}

Float64List _mix2(Float64List a, Float64List b, double gain) {
  final y = Float64List.fromList(a);
  for (var i = 0; i < min(a.length, b.length); i++) {
    y[i] += b[i] * gain;
  }
  return y;
}

Float64List _seq(List<(double freq, double at)> notes, double total,
    {double dur = 0.25, double decay = 7, bool wood = false}) {
  final out = _buf(total);
  for (final (f, at) in notes) {
    _mix(
        out,
        wood ? _marimba(f, dur, decay: decay) : _bell(f, dur, decay: decay),
        at);
  }
  return out;
}

Uint8List _wav(Float64List samples, {double peak = 0.8, bool fade = true}) {
  final dc = samples.fold<double>(0, (m, v) => m + v) / samples.length;
  samples = Float64List.fromList([for (final v in samples) v - dc]);
  if (fade) {
    // 2 ms in, 8 ms out: no pops where a one-shot starts or stops.
    final a = (0.002 * _sr).round(), z = (0.008 * _sr).round();
    for (var i = 0; i < a; i++) {
      samples[i] *= i / a;
    }
    for (var i = 0; i < z; i++) {
      samples[samples.length - 1 - i] *= i / z;
    }
  }
  final top = samples.fold<double>(0, (m, v) => max(m, v.abs()));
  final k = top == 0 ? 1 : peak / top;
  final data = ByteData(44 + samples.length * 2);
  void tag(int at, String s) {
    for (var i = 0; i < 4; i++) {
      data.setUint8(at + i, s.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  data.setUint32(4, 36 + samples.length * 2, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little); // PCM
  data.setUint16(22, 1, Endian.little); // mono
  data.setUint32(24, _sr, Endian.little);
  data.setUint32(28, _sr * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  tag(36, 'data');
  data.setUint32(40, samples.length * 2, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    final v = (samples[i] * k).clamp(-1.0, 1.0);
    data.setInt16(44 + i * 2, (v * 32767).round(), Endian.little);
  }
  return data.buffer.asUint8List();
}

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
      _mix(beats, _lp(_hp(_noise(0.05, decay: 60), 5000), 9000), i * bar + s * eighth,
          s.isOdd ? 0.04 : 0.02);
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
