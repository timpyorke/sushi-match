// ignore_for_file: avoid_print
// Synthesises the placeholder sound effects and BGM into assets/audio/ as
// 16-bit mono WAV. Swap any file for real audio of the same name later; the
// game only refers to the file names (see lib/services/audio.dart).
//
//   dart run tool/gen_sounds.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const _sr = 22050;
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

/// A bell-ish tone: fundamental plus a soft octave, exponential decay.
Float64List _bell(double freq, double dur, {double decay = 6}) {
  final b = _buf(dur);
  for (var i = 0; i < b.length; i++) {
    final t = i / _sr;
    final env = exp(-decay * t) * min(1, t * 400);
    b[i] = env *
        (sin(2 * pi * freq * t) + 0.35 * sin(2 * pi * freq * 2 * t)) /
        1.35;
  }
  return b;
}

/// A sine that glides from [f0] to [f1].
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
    b[i] = w / (1 + square) * exp(-decay * t) * min(1, t * 300);
  }
  return b;
}

/// Low-passed (or high-passed) noise burst.
Float64List _noise(double dur,
    {double decay = 8, double cutoff = 0.3, bool high = false}) {
  final b = _buf(dur);
  var lp = 0.0;
  for (var i = 0; i < b.length; i++) {
    final t = i / _sr;
    final n = _rng.nextDouble() * 2 - 1;
    lp += (n - lp) * cutoff;
    b[i] = (high ? n - lp : lp) * exp(-decay * t);
  }
  return b;
}

/// Karplus-Strong plucked string: the koto / shamisen stand-in.
Float64List _pluck(double freq, double dur, {double damp = 0.996}) {
  final n = max(2, (_sr / freq).round());
  final line = Float64List(n);
  for (var i = 0; i < n; i++) {
    line[i] = _rng.nextDouble() * 2 - 1;
  }
  final b = _buf(dur);
  var p = 0;
  for (var i = 0; i < b.length; i++) {
    final cur = line[p];
    final next = line[(p + 1) % n];
    line[p] = (cur + next) * 0.5 * damp;
    b[i] = cur;
    p = (p + 1) % n;
  }
  return b;
}

Float64List _seq(List<(double freq, double at)> notes, double total,
    {double dur = 0.25, double decay = 7}) {
  final out = _buf(total);
  for (final (f, at) in notes) {
    _mix(out, _bell(f, dur, decay: decay), at);
  }
  return out;
}

Uint8List _wav(Float64List samples, {double peak = 0.8}) {
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

  out['swap'] = _sweep(380, 520, 0.08, decay: 25);
  out['invalid'] = () {
    final b = _buf(0.22);
    _mix(b, _sweep(220, 200, 0.1, decay: 12, square: 0.6), 0);
    _mix(b, _sweep(180, 150, 0.12, decay: 12, square: 0.6), 0.1);
    return b;
  }();

  for (var i = 0; i < _ladder.length; i++) {
    final b = _buf(0.3);
    _mix(b, _bell(_ladder[i], 0.3, decay: 9), 0);
    _mix(b, _noise(0.04, decay: 80, cutoff: 0.5, high: true), 0, 0.25);
    out['match_${i + 1}'] = b;
  }

  out['special'] = _seq([
    for (var i = 0; i < 5; i++) (_ladder[i] * 1.5, i * 0.06),
  ], 0.6, dur: 0.3, decay: 8);

  out['boom'] = () {
    final b = _buf(0.55);
    _mix(b, _noise(0.55, decay: 6, cutoff: 0.12), 0);
    _mix(b, _sweep(120, 40, 0.5, decay: 5), 0, 1.4);
    return b;
  }();

  out['crack'] = () {
    final b = _buf(0.14);
    _mix(b, _noise(0.14, decay: 30, cutoff: 0.6, high: true), 0);
    _mix(b, _sweep(900, 500, 0.05, decay: 40), 0, 0.5);
    return b;
  }();

  out['chime'] = _seq([(1318.5, 0), (1760, 0.09)], 0.55, dur: 0.45, decay: 6);
  out['unlock'] =
      _seq([(784, 0), (988, 0.07), (1318.5, 0.14)], 0.6, dur: 0.35, decay: 7);
  out['meow'] = () {
    final b = _buf(0.3);
    _mix(b, _sweep(620, 900, 0.14, decay: 4), 0);
    _mix(b, _sweep(900, 520, 0.16, decay: 6), 0.14);
    return b;
  }();
  out['shuffle'] = () {
    final b = _buf(0.45);
    for (var i = 0; i < 6; i++) {
      _mix(b, _noise(0.08, decay: 25, cutoff: 0.35, high: true), i * 0.06);
    }
    return b;
  }();
  out['coin'] = _seq([(988, 0), (1318.5, 0.06)], 0.35, dur: 0.25, decay: 10);

  out['win'] = _seq([
    (523.25, 0),
    (659.25, 0.14),
    (783.99, 0.28),
    (1046.5, 0.42),
    (783.99, 0.62),
    (1046.5, 0.74),
  ], 1.5, dur: 0.6, decay: 4);
  out['lose'] = _seq([
    (392, 0),
    (329.63, 0.25),
    (261.63, 0.5),
    (196, 0.8),
  ], 1.6, dur: 0.6, decay: 4);

  return out;
}

/// ~20 s lo-fi loop in the Hirajoshi scale (A B C E F): plucked melody over a
/// sparse bass, tempo 96 bpm, 8 bars.
Float64List _bgm() {
  const bpm = 96;
  const eighth = 60 / bpm / 2;
  const bars = 8;
  const total = bars * 8 * eighth;
  final out = _buf(total);

  const a = [5, -1, 7, -1, 8, -1, 7, 6, 5, -1, 3, -1, 5, -1, -1, -1];
  const b = [8, -1, 9, -1, 8, -1, 7, -1, 6, -1, 5, -1, 3, -1, -1, -1];
  const b2 = [8, -1, 9, -1, 8, -1, 7, -1, 6, -1, 5, -1, 5, -1, -1, -1];
  const scale = [
    220.0, 246.94, 261.63, 329.63, 349.23, // A3 B3 C4 E4 F4
    440.0, 493.88, 523.25, 659.25, 698.46, 880.0, // A4 B4 C5 E5 F5 A5
  ];
  final melody = [...a, ...b, ...a, ...b2];
  for (var i = 0; i < melody.length; i++) {
    if (melody[i] < 0) continue;
    _mix(out, _pluck(scale[melody[i]], 1.4), i * eighth, 0.3);
  }
  for (var bar = 0; bar < bars; bar++) {
    final root = bar.isEven ? 110.0 : 87.31; // A2 / F2
    _mix(out, _pluck(root, 1.8, damp: 0.998), bar * 8 * eighth, 0.55);
    _mix(
        out, _pluck(root * 1.5, 1.2, damp: 0.998), (bar * 8 + 4) * eighth, 0.3);
  }
  return out;
}

void main() {
  final dir = Directory('assets/audio')..createSync(recursive: true);
  for (final e in _sfx().entries) {
    File('${dir.path}/${e.key}.wav').writeAsBytesSync(_wav(e.value));
  }
  File('${dir.path}/bgm.wav').writeAsBytesSync(_wav(_bgm(), peak: 0.6));
  for (final f in dir.listSync().whereType<File>().toList()
    ..sort((x, y) => x.path.compareTo(y.path))) {
    print('${f.path}  ${(f.lengthSync() / 1024).round()} KB');
  }
}
