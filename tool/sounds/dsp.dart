part of '../gen_sounds.dart';

// Synthesis building blocks: buffers, envelopes, filters, reverb, voices
// and WAV encoding.

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
