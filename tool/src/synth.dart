/// Building blocks for the placeholder sounds that
/// `tool/make_placeholder_sounds.dart` makes: notes and scores, ringing
/// partials, oscillators, filters, reverb, loudness and WAV files. Pure
/// Dart, so making the sounds needs no packages and no downloads.
library;

import 'dart:math';
import 'dart:typed_data';

/// Samples per second in every placeholder clip: enough for a bird's
/// whistle, at half the size of CD quality.
const sampleRate = 22050;

/// Partials at or above this frequency are left out, so they can't alias.
const double _highest = sampleRate * 0.45;

/// The number of samples in [seconds].
int samplesIn(double seconds) => (seconds * sampleRate).round();

/// Silence, [seconds] long, to mix sounds into.
Float64List silence(double seconds) => Float64List(samplesIn(seconds));

/// Adds [sound] into [track] [at] seconds in, times [gain]. What runs past
/// the end of [track] is dropped.
void mix(Float64List track, Float64List sound, double at, {double gain = 1}) {
  final start = samplesIn(at);
  final end = min(track.length, start + sound.length);
  for (var i = max(start, 0); i < end; i++) {
    track[i] += gain * sound[i - start];
  }
}

/// The frequency of the note [name] in Hz, such as `A4` (440 Hz), `F#5` or
/// `Bb3`.
double note(String name) {
  final match = _noteName.firstMatch(name);
  if (match == null) throw ArgumentError.value(name, 'name', 'is not a note');
  final semitones =
      _semitonesFromA[match[1]]! +
      switch (match[2]) {
        '#' => 1,
        'b' => -1,
        _ => 0,
      } +
      12 * (int.parse(match[3]!) - 4);
  return 440 * pow(2, semitones / 12).toDouble();
}

final _noteName = RegExp(r'^([A-G])([#b]?)(\d)$');

const _semitonesFromA = {
  'C': -9,
  'D': -7,
  'E': -5,
  'F': -4,
  'G': -2,
  'A': 0,
  'B': 2,
};

/// One note of a [score]. A rest has no name; a roll strikes the note again
/// and again.
typedef Note = ({String? name, double beats, bool roll});

/// The notes of [text]: note names such as `C5`, or `-` for a rest, each
/// followed by `/beats` when it is not [unit] beats long, and by `~` for a
/// roll. A `|` marks a bar line, to make scores easier to read.
List<Note> score(String text, {double unit = 1}) => [
  for (final token in text.split(' '))
    if (token.isNotEmpty && token != '|') _noteOf(token, unit),
];

Note _noteOf(String token, double unit) {
  final parts = token.split('/');
  final name = parts.first.replaceAll('~', '');
  return (
    name: name == '-' ? null : name,
    beats: parts.length > 1 ? double.parse(parts[1]) : unit,
    roll: parts.first.endsWith('~'),
  );
}

/// Plays [text], a [score], on [voice] into [track]: from [at] seconds in,
/// one beat every [beat] seconds, times [gain]. A roll strikes its note
/// every [rollEvery] seconds.
void play(
  Float64List track,
  String text, {
  required Float64List Function(double frequency, double seconds) voice,
  required double at,
  required double beat,
  double unit = 1,
  double gain = 1,
  double rollEvery = 0.06,
}) {
  var time = at;
  for (final (:name, :beats, :roll) in score(text, unit: unit)) {
    final length = beats * beat;
    if (name != null && roll) {
      for (var t = 0.0; t < length - rollEvery / 2; t += rollEvery) {
        final accent = t == 0 ? 1 : 0.7;
        mix(track, voice(note(name), rollEvery), time + t, gain: gain * accent);
      }
    } else if (name != null) {
      mix(track, voice(note(name), length), time, gain: gain);
    }
    time += length;
  }
}

/// One partial of a struck or plucked sound: a sine wave of `frequency` Hz
/// that starts at `amplitude` and falls to about a third every `decay`
/// seconds.
typedef Partial = ({double frequency, double amplitude, double decay});

/// [partials] ringing together for [seconds], after an attack of [attack]
/// seconds: a bell, a string or a wooden bar. Partials too high for the
/// sample rate are left out.
Float64List ring(
  Iterable<Partial> partials,
  double seconds, {
  double attack = 0.002,
}) {
  final out = silence(seconds);
  for (final (:frequency, :amplitude, :decay) in partials) {
    if (frequency <= 0 || frequency >= _highest) continue;
    // A pointer that turns by one sample's angle and shrinks by one
    // sample's decay at each step; its height is the fading sine.
    final angle = 2 * pi * frequency / sampleRate;
    final shrink = exp(-1 / (decay * sampleRate));
    final turnX = shrink * cos(angle);
    final turnY = shrink * sin(angle);
    var x = amplitude;
    var y = 0.0;
    for (var i = 0; i < out.length; i++) {
      out[i] += y;
      final nextX = x * turnX - y * turnY;
      y = x * turnY + y * turnX;
      x = nextX;
    }
  }
  final ramp = min(samplesIn(attack), out.length);
  for (var i = 0; i < ramp; i++) {
    out[i] *= i / ramp;
  }
  return out;
}

/// White noise, [seconds] long, that falls to about a third every [decay]
/// seconds: a hiss, a cymbal or the tap of a mallet.
Float64List noise(
  Random random,
  double seconds, {
  double decay = double.infinity,
}) {
  final out = silence(seconds);
  final fall = exp(-1 / (decay * sampleRate));
  var level = 1.0;
  for (var i = 0; i < out.length; i++) {
    out[i] = level * (2 * random.nextDouble() - 1);
    level *= fall;
  }
  return out;
}

/// Which part of the sound a [Filter] lets through.
enum Pass { low, band, high }

/// A filter whose cutoff may change on every sample: a two-pole state
/// variable filter in Andrew Simper's form, stable up to Nyquist.
final class Filter {
  new(this.pass, this.cutoff, {this.q = sqrt1_2});

  final Pass pass;

  /// In Hz; may change between samples.
  double cutoff;

  /// How sharp the filter is: higher rings more.
  final double q;

  double _state1 = 0;
  double _state2 = 0;

  /// The next filtered sample.
  double process(double input) {
    final g = tan(pi * min(cutoff, 0.49 * sampleRate) / sampleRate);
    final k = 1 / q;
    final a1 = 1 / (1 + g * (g + k));
    final a2 = g * a1;
    final a3 = g * a2;
    final v3 = input - _state2;
    final v1 = a1 * _state1 + a2 * v3;
    final v2 = _state2 + a2 * _state1 + a3 * v3;
    _state1 = 2 * v1 - _state1;
    _state2 = 2 * v2 - _state2;
    return switch (pass) {
      .low => v2,
      .band => k * v1,
      .high => input - k * v1 - v2,
    };
  }

  /// [samples], filtered in place.
  Float64List apply(Float64List samples) {
    for (var i = 0; i < samples.length; i++) {
      samples[i] = process(samples[i]);
    }
    return samples;
  }
}

/// The shape of an [Oscillator]'s wave.
enum Wave { saw, pulse, triangle }

/// A wave whose frequency may change on every sample. Saw and pulse waves
/// are smoothed where they jump (PolyBLEP), so they don't alias.
final class Oscillator {
  new(this.wave, {this.width = 0.5});

  final Wave wave;

  /// How much of each cycle a pulse wave is high, from 0 to 1.
  final double width;

  double _phase = 0;

  /// The next sample of a wave of [frequency] Hz.
  double next(double frequency) {
    final step = frequency / sampleRate;
    final phase = _phase;
    _phase = (phase + step) % 1;
    return switch (wave) {
      .saw => 2 * phase - 1 - _blep(phase, step),
      .pulse =>
        (phase < width ? 1 : -1) +
            _blep(phase, step) -
            _blep((phase - width) % 1, step),
      .triangle => 1 - 4 * (phase - 0.5).abs(),
    };
  }
}

/// What smooths a jump of a wave at [phase] 0, for a wave that moves [step]
/// of a cycle per sample.
double _blep(double phase, double step) {
  if (phase < step) {
    final t = phase / step;
    return 2 * t - t * t - 1;
  }
  if (phase > 1 - step) {
    final t = (phase - 1) / step;
    return t * t + 2 * t + 1;
  }
  return 0;
}

/// [dry] with the echo of a room added: Freeverb's comb and all-pass
/// filters (Jezar at Dreamscape, public domain), in mono and tuned for
/// 22,050 Hz. [room] from 0 to 1 sets how long it rings, [damp] how dull
/// the echo is, and [wet] how much of it is added.
Float64List reverb(
  Float64List dry, {
  double room = 0.5,
  double damp = 0.5,
  double wet = 0.2,
}) {
  const combs = [558, 594, 638, 678, 711, 745, 778, 808];
  const allPasses = [278, 221, 171, 113];
  final feedback = 0.7 + 0.28 * room;
  final echo = Float64List(dry.length);
  for (final length in combs) {
    final buffer = Float64List(length);
    var index = 0;
    var store = 0.0;
    for (var i = 0; i < dry.length; i++) {
      final out = buffer[index];
      store = out * (1 - damp) + store * damp;
      buffer[index] = 0.015 * dry[i] + feedback * store;
      index = (index + 1) % length;
      echo[i] += out;
    }
  }
  for (final length in allPasses) {
    final buffer = Float64List(length);
    var index = 0;
    for (var i = 0; i < echo.length; i++) {
      final buffered = buffer[index];
      final input = echo[i];
      echo[i] = buffered - input;
      buffer[index] = input + 0.5 * buffered;
      index = (index + 1) % length;
    }
  }
  return Float64List.fromList([
    for (var i = 0; i < dry.length; i++) dry[i] + 3 * wet * echo[i],
  ]);
}

/// Drives [samples] into soft clipping, in place: louder for the same peak,
/// like a mastering limiter, at the cost of a little edge. [drive] above 1
/// clips more.
void saturate(Float64List samples, double drive) {
  final peak = peakOf(samples);
  final top = _tanh(drive);
  for (var i = 0; i < samples.length; i++) {
    samples[i] = peak * _tanh(drive * samples[i] / peak) / top;
  }
}

double _tanh(double x) {
  final e = exp(2 * x.clamp(-20, 20));
  return (e - 1) / (e + 1);
}

/// Fades [samples] in over [fadeIn] seconds and out over [fadeOut] seconds,
/// in place, so the clip starts and ends without a click.
void fade(Float64List samples, {double fadeIn = 0.005, double fadeOut = 0.5}) {
  final inLength = min(samplesIn(fadeIn), samples.length);
  for (var i = 0; i < inLength; i++) {
    samples[i] *= i / inLength;
  }
  final outLength = min(samplesIn(fadeOut), samples.length);
  for (var i = 0; i < outLength; i++) {
    samples[samples.length - 1 - i] *= 0.5 - 0.5 * cos(pi * i / outLength);
  }
}

/// The largest sample of [samples], ignoring the sign.
double peakOf(Float64List samples) =>
    samples.fold<double>(0, (peak, sample) => max(peak, sample.abs()));

/// The highest peak a clip may have: -1 dBFS, so it never distorts.
final double ceiling = pow(10, -1 / 20).toDouble();

/// [samples] made as loud as [lufs], unless that would take a peak above
/// [ceiling]: then only as loud as the ceiling allows.
Float64List normalized(Float64List samples, double lufs) {
  final toLoudness = pow(10, (lufs - loudness(samples)) / 20).toDouble();
  final gain = min(toLoudness, ceiling / peakOf(samples));
  return Float64List.fromList([for (final sample in samples) gain * sample]);
}

/// The loudness of [samples] in LUFS, measured as ITU-R BS.1770 says:
/// weighted the way ears hear, over 400-ms blocks, leaving out the quiet
/// ones.
double loudness(Float64List samples) {
  final weighted = _kWeighted(samples);
  final block = samplesIn(0.4);
  final hop = samplesIn(0.1);
  // Running sums of squares, so each block's power is one subtraction.
  final sums = Float64List(weighted.length + 1);
  for (var i = 0; i < weighted.length; i++) {
    sums[i + 1] = sums[i] + weighted[i] * weighted[i];
  }
  final powers = [
    for (var start = 0; start + block <= weighted.length; start += hop)
      (sums[start + block] - sums[start]) / block,
  ];
  double lufsOf(double power) => -0.691 + 10 * log(power) / ln10;
  double meanOf(Iterable<double> values) =>
      values.reduce((sum, value) => sum + value) / values.length;
  final audible = [
    for (final power in powers)
      if (power > 0 && lufsOf(power) > -70) power,
  ];
  if (audible.isEmpty) return double.negativeInfinity;
  final gate = lufsOf(meanOf(audible)) - 10;
  return lufsOf(meanOf(audible.where((power) => lufsOf(power) > gate)));
}

/// [samples] through the K-weighting of ITU-R BS.1770: a shelf that lifts
/// the highs by 4 dB, then a high-pass at 38 Hz. The coefficients come from
/// Brecht De Man's derivation, so they fit any sample rate.
Float64List _kWeighted(Float64List samples) {
  const shelfGain = 3.999843853973347;
  const shelfQ = 0.7071752369554196;
  const shelfFrequency = 1681.974450955533;
  final k = tan(pi * shelfFrequency / sampleRate);
  final vh = pow(10, shelfGain / 20).toDouble();
  final vb = pow(vh, 0.4996667741545416).toDouble();
  final a0 = 1 + k / shelfQ + k * k;
  final shelved = _biquad(
    samples,
    b0: (vh + vb * k / shelfQ + k * k) / a0,
    b1: 2 * (k * k - vh) / a0,
    b2: (vh - vb * k / shelfQ + k * k) / a0,
    a1: 2 * (k * k - 1) / a0,
    a2: (1 - k / shelfQ + k * k) / a0,
  );

  const passQ = 0.5003270373238773;
  const passFrequency = 38.13547087602444;
  final kPass = tan(pi * passFrequency / sampleRate);
  final a0Pass = 1 + kPass / passQ + kPass * kPass;
  return _biquad(
    shelved,
    b0: 1,
    b1: -2,
    b2: 1,
    a1: 2 * (kPass * kPass - 1) / a0Pass,
    a2: (1 - kPass / passQ + kPass * kPass) / a0Pass,
  );
}

/// [samples] through a biquad filter whose `a0` is 1.
Float64List _biquad(
  Float64List samples, {
  required double b0,
  required double b1,
  required double b2,
  required double a1,
  required double a2,
}) {
  final out = Float64List(samples.length);
  var x1 = 0.0;
  var x2 = 0.0;
  var y1 = 0.0;
  var y2 = 0.0;
  for (var i = 0; i < samples.length; i++) {
    final x = samples[i];
    final y = b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2;
    x2 = x1;
    x1 = x;
    y2 = y1;
    y1 = y;
    out[i] = y;
  }
  return out;
}

/// [samples], from -1 to 1, as the bytes of a WAV file: 16-bit PCM, mono.
Uint8List wav(Float64List samples) {
  final bytes = ByteData(44 + 2 * samples.length)
    ..setUint32(0, 0x52494646) // "RIFF"
    ..setUint32(4, 36 + 2 * samples.length, Endian.little)
    ..setUint32(8, 0x57415645) // "WAVE"
    ..setUint32(12, 0x666D7420) // "fmt "
    ..setUint32(16, 16, Endian.little) // the size of this chunk
    ..setUint16(20, 1, Endian.little) // PCM
    ..setUint16(22, 1, Endian.little) // mono
    ..setUint32(24, sampleRate, Endian.little)
    ..setUint32(28, 2 * sampleRate, Endian.little) // bytes per second
    ..setUint16(32, 2, Endian.little) // bytes per sample
    ..setUint16(34, 16, Endian.little) // bits per sample
    ..setUint32(36, 0x64617461) // "data"
    ..setUint32(40, 2 * samples.length, Endian.little);
  for (final (i, sample) in samples.indexed) {
    final value = (32767 * sample.clamp(-1, 1)).round();
    bytes.setInt16(44 + 2 * i, value, Endian.little);
  }
  return bytes.buffer.asUint8List();
}

/// Random numbers that are the same on every Dart version, unlike those of
/// Dart's own `Random`, so the script always makes the same files: a 32-bit
/// xorshift generator.
final class Xorshift implements Random {
  new(int seed) : _state = (seed * 0x9E3779B1 + 0x7F4A7C15) & 0xFFFFFFFF | 1;

  int _state;

  int _next() {
    var x = _state;
    x ^= (x << 13) & 0xFFFFFFFF;
    x ^= x >> 17;
    x ^= (x << 5) & 0xFFFFFFFF;
    return _state = x;
  }

  @override
  double nextDouble() => _next() / 0x100000000;

  @override
  int nextInt(int max) => _next() % max;

  @override
  bool nextBool() => _next().isOdd;

  /// A number from [low] to [high].
  double between(double low, double high) => low + (high - low) * nextDouble();
}
