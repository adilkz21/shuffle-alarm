// Makes the placeholder sounds: nine clips of our own, three per intensity,
// synthesized here, so they need no downloads and no license but ours. Each
// one is a different kind of sound, so a half-awake tester can tell them
// apart. Run it from the project folder:
//
//   dart run tool/make_placeholder_sounds.dart
//
// It writes assets/library/placeholder/*.wav and puts their entries into
// assets/library/manifest.json, keeping the entries of other genres. The
// same script always makes the same files. Why: docs/DECISIONS.md (D14).
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'src/synth.dart';

/// The genre of the placeholder sounds, and the name of their folder.
const _genre = 'placeholder';

/// How loud the sounds of each intensity are, in LUFS: the gentle ones a
/// little softer. A sound whose peaks would go over -1 dBFS stays softer.
const _loudness = <int, double>{1: -19, 2: -17, 3: -15};

/// A placeholder sound: what the manifest says about it, and how to make it.
typedef _Recipe = ({
  String name,
  String title,
  int intensity,
  Float64List Function() make,
});

const List<_Recipe> _recipes = [
  (name: 'birds', title: 'Birds', intensity: 1, make: _birds),
  (name: 'harp', title: 'Harp', intensity: 1, make: _harp),
  (name: 'music-box', title: 'Music Box', intensity: 1, make: _musicBox),
  (name: 'xylophone', title: 'Xylophone', intensity: 2, make: _xylophone),
  (name: 'video-game', title: 'Video Game', intensity: 2, make: _videoGame),
  (name: 'bell-tower', title: 'Bell Tower', intensity: 2, make: _bellTower),
  (name: 'drums', title: 'Drums', intensity: 3, make: _drums),
  (name: 'alarm-clock', title: 'Alarm Clock', intensity: 3, make: _alarmClock),
  (name: 'fanfare', title: 'Fanfare', intensity: 3, make: _fanfare),
];

void main() {
  final manifest = File('assets/library/manifest.json');
  if (!File('pubspec.yaml').existsSync() || !manifest.parent.existsSync()) {
    stderr.writeln(
      'Run this from the project folder: '
      'dart run tool/make_placeholder_sounds.dart',
    );
    exitCode = 64;
    return;
  }
  final others = _otherEntries(manifest);
  final folder = Directory('${manifest.parent.path}/$_genre')
    ..createSync(recursive: true);
  final entries = <Map<String, Object>>[];
  for (final (:name, :title, :intensity, :make) in _recipes) {
    final samples = make();
    fade(samples);
    final clip = normalized(samples, _loudness[intensity]!);
    File('${folder.path}/$name.wav').writeAsBytesSync(wav(clip));
    final seconds = clip.length / sampleRate;
    entries.add({
      'id': '$_genre-$name',
      'title': title,
      'artist': 'Shuffle Alarm',
      'genre': _genre,
      'intensity': intensity,
      'file': '$_genre/$name.wav',
      'durationSec': seconds == seconds.roundToDouble()
          ? seconds.round()
          : seconds,
      'license': 'original',
      'sourceUrl': '',
      'attribution': '',
    });
    final peak = 20 * log(peakOf(clip)) / ln10;
    stdout.writeln(
      '${'$name.wav'.padRight(16)} level $intensity  ${seconds}s  '
      'peak ${peak.toStringAsFixed(1)} dBFS  '
      '${loudness(clip).toStringAsFixed(1)} LUFS',
    );
  }
  final json = const JsonEncoder.withIndent('  ').convert({
    'sounds': [...others, ...entries],
  });
  manifest.writeAsStringSync('$json\n');
  stdout.writeln('Wrote ${entries.length} clips to ${folder.path}.');
}

/// The entries of other genres in [manifest], which this script keeps.
List<Object?> _otherEntries(File manifest) {
  if (!manifest.existsSync()) return [];
  final json = jsonDecode(manifest.readAsStringSync());
  if (json case {'sounds': final List<Object?> sounds}) {
    return [
      for (final entry in sounds)
        if (entry is! Map<String, Object?> || entry['genre'] != _genre) entry,
    ];
  }
  throw FormatException('${manifest.path} has no "sounds" list.');
}

// Gentle -------------------------------------------------------------------

/// Birds: quick warbles, a two-note whistle, trills and slurred calls,
/// never more than about half a second apart.
Float64List _birds() {
  final random = Xorshift(1);
  final track = silence(22);
  var at = 0.05;
  while (at < 21) {
    final call = switch (random.nextInt(4)) {
      0 => _warble(random),
      1 => _whistle(random),
      2 => _trill(random),
      _ => _slurs(random),
    };
    mix(track, call, at, gain: random.between(0.6, 1));
    if (random.nextInt(3) == 0) {
      // A second bird answers over the first.
      final answer = at + random.between(0.2, 0.5);
      mix(track, _warble(random), answer, gain: random.between(0.3, 0.5));
    }
    at += call.length / sampleRate + random.between(0.15, 0.5);
  }
  return reverb(track, room: 0.4, wet: 0.12);
}

/// One whistled note that glides through [frequencies], evenly spread over
/// [seconds].
Float64List _chirp(List<double> frequencies, double seconds) {
  final out = silence(seconds);
  final steps = frequencies.length - 1;
  var phase = 0.0;
  for (var i = 0; i < out.length; i++) {
    final position = steps * i / out.length;
    final step = min(position.floor(), steps - 1);
    final from = frequencies[step];
    final to = frequencies[step + 1];
    phase +=
        2 * pi * from * exp((position - step) * log(to / from)) / sampleRate;
    final swell = sin(pi * i / out.length);
    out[i] = swell * swell * sin(phase);
  }
  return out;
}

/// [sounds] one after another, [gap] seconds apart.
Float64List _phrase(List<Float64List> sounds, double gap) {
  final gapLength = samplesIn(gap);
  final out = Float64List(
    sounds.fold(0, (length, sound) => length + sound.length + gapLength),
  );
  var at = 0;
  for (final sound in sounds) {
    out.setRange(at, at + sound.length, sound);
    at += sound.length + gapLength;
  }
  return out;
}

/// A quick warble of four to seven short notes.
Float64List _warble(Xorshift random) => _phrase([
  for (var i = 4 + random.nextInt(4); i > 0; i--) _shortChirp(random),
], random.between(0.025, 0.05));

Float64List _shortChirp(Xorshift random) {
  final from = random.between(2600, 4000);
  final to = from * random.between(0.8, 1.25);
  return _chirp([from, to], random.between(0.05, 0.1));
}

/// A clear two-note whistle, high and then lower.
Float64List _whistle(Xorshift random) {
  final pitch = random.between(0.95, 1.05);
  return _phrase([
    _chirp([3700 * pitch, 3650 * pitch], 0.3),
    _chirp([3000 * pitch, 2950 * pitch], 0.38),
  ], 0.07);
}

/// A trill: a fast run of short notes that falls a little.
Float64List _trill(Xorshift random) {
  final top = random.between(4200, 4800);
  return _phrase([
    for (var i = 12 + random.nextInt(7); i > 0; i--)
      _chirp([top - 25 * i, top - 25 * i - 300], 0.028),
  ], 0.016);
}

/// Slurred calls that rise and fall, like a robin's.
Float64List _slurs(Xorshift random) => _phrase([
  for (var i = 2 + random.nextInt(3); i > 0; i--) _slur(random),
], 0.12);

Float64List _slur(Xorshift random) {
  final low = random.between(2000, 2400);
  final high = low * random.between(1.3, 1.5);
  return _chirp([low, high, 1.1 * low], random.between(0.22, 0.3));
}

/// A harp in D major: a glissando up, broken chords, and a last chord with
/// a glissando down.
Float64List _harp() {
  final track = silence(24);
  play(
    track,
    'D4 E4 F#4 G4 A4 B4 C#5 D5 E5 F#5 G5 A5 B5 C#6 D6',
    voice: _string,
    at: 0.05,
    beat: 0.045,
    gain: 0.45,
  );
  // Each bar plays its chord from the bottom up and back: root, fifth,
  // octave, tenth, the fifth an octave up, and down again.
  const chords = [
    ['D3', 'A3', 'D4', 'F#4', 'A4'],
    ['B2', 'F#3', 'B3', 'D4', 'F#4'],
    ['G2', 'D3', 'G3', 'B3', 'D4'],
    ['A2', 'E3', 'A3', 'C#4', 'E4'],
    ['D3', 'A3', 'D4', 'F#4', 'A4'],
    ['E3', 'B3', 'E4', 'G4', 'B4'],
    ['A2', 'E3', 'A3', 'C#4', 'E4'],
  ];
  const pattern = [0, 1, 2, 3, 4, 3, 2, 1];
  play(
    track,
    [
      for (final chord in chords) [for (final i in pattern) chord[i]].join(' '),
    ].join(' | '),
    voice: _string,
    at: 0.85,
    beat: 0.375,
    gain: 0.55,
  );
  play(
    track,
    'D3 A3 D4 F#4 A4 D5',
    voice: _string,
    at: 21.85,
    beat: 0.06,
    gain: 0.55,
  );
  play(
    track,
    'D6 C#6 B5 A5 G5 F#5 E5 D5',
    voice: _string,
    at: 22.4,
    beat: 0.05,
    gain: 0.35,
  );
  return reverb(track, room: 0.75, damp: 0.4, wet: 0.25);
}

/// A plucked string: harmonics that fade faster the higher they are,
/// slightly stretched like those of a real string. They are a little
/// brighter than a real harp's, so phone speakers still play them.
Float64List _string(double frequency, double _) => ring(
  [
    for (var k = 1; k <= 12; k++)
      (
        frequency: frequency * k * sqrt(1 + 0.0001 * k * k),
        amplitude: sin(0.27 * pi * k).abs() / pow(k, 1.5),
        decay: 2.5 * pow(220 / frequency, 0.3).toDouble() / (1 + 0.5 * (k - 1)),
      ),
  ],
  3.5,
  attack: 0.003,
);

/// A music box in F major: a slow waltz on high tines over a low
/// "oom-pah-pah".
Float64List _musicBox() {
  final random = Xorshift(3);
  final track = silence(24);
  Float64List tine(double frequency, double _) => _tine(random, frequency);
  const beat = 0.625; // 96 beats a minute, three to a bar
  play(
    track,
    'A5 C6 F6 | E6/1.5 D6/.5 C6 | Bb5 D6 G6 | F6/3 | '
    'A6 G6 F6 | E6 F6 G6 | D6 E6 F6 | C6/3 | '
    'A5 C6 F6 | A6/1.5 G6/.5 F6 | Bb6 A6 G6 | F6/3',
    voice: tine,
    at: 0.05,
    beat: beat,
  );
  const chords = [
    ('F4', 'A4', 'C5'),
    ('C4', 'E4', 'G4'),
    ('Bb3', 'D4', 'F4'),
    ('F4', 'A4', 'C5'),
    ('F4', 'A4', 'C5'),
    ('C4', 'E4', 'G4'),
    ('Bb3', 'D4', 'F4'),
    ('C4', 'E4', 'G4'),
    ('F4', 'A4', 'C5'),
    ('C4', 'E4', 'G4'),
    ('Bb3', 'D4', 'F4'),
    ('F4', 'A4', 'C5'),
  ];
  // The root on the first beat, the rest of the chord on the other two.
  for (final (bars, gain) in [
    ([for (final (root, _, _) in chords) '$root - -'], 0.45),
    ([for (final (_, third, _) in chords) '- $third $third'], 0.22),
    ([for (final (_, _, fifth) in chords) '- $fifth $fifth'], 0.22),
  ]) {
    play(
      track,
      bars.join(' | '),
      voice: tine,
      at: 0.05,
      beat: beat,
      gain: gain,
    );
  }
  return reverb(track, room: 0.6);
}

/// A music box tine: a clear tone with a quiet octave and a short metallic
/// "ting" above it, plucked with a tiny click.
Float64List _tine(Xorshift random, double frequency) {
  final sound = ring(
    [
      (frequency: frequency, amplitude: 1, decay: 1.3),
      (frequency: 2 * frequency, amplitude: 0.12, decay: 0.45),
      (frequency: 6.27 * frequency, amplitude: 0.25, decay: 0.08),
    ],
    3.2,
    attack: 0.001,
  );
  final click = Filter(.high, 4000).apply(noise(random, 0.006, decay: 0.0015));
  mix(sound, click, 0, gain: 0.25);
  return sound;
}

// Medium -------------------------------------------------------------------

/// A xylophone in C major: a bouncy tune on hard wooden bars, with a roll
/// on the long notes and lower bars on the main beats.
Float64List _xylophone() {
  final random = Xorshift(4);
  final track = silence(24);
  Float64List bar(double frequency, double _) => _woodBar(random, frequency);
  const beat = 60 / 126;
  const a = 'C5 E5 G5 E5 C6 - G5 -';
  const b = 'A5 G5 F5 E5 D5 E5 F5 D5';
  const c = 'E5 G5 C6 G5 E5 G5 A5 B5';
  const d = 'C6~/2 G5 E5 C5 -';
  const e = 'F5 A5 C6 A5 F5 A5 C6 A5';
  const f = 'G5 B5 D6 B5 G5 F5 E5 D5';
  const g = 'E5 C5 E5 G5 C6 B5 A5 B5';
  const h = 'C6/1 G5/1 C5/1 -/1';
  play(
    track,
    [a, b, c, d, e, f, g, h, a, b, c, d].join(' | '),
    voice: bar,
    at: 0.05,
    beat: beat,
    unit: 0.5,
  );
  play(
    track,
    'C4 - G3 - | F4 - G3 - | C4 - E4 - | C4 - G3 - | '
    'F4 - C4 - | G3 - D4 - | C4 - G3 - | C4 G3 C4 - | '
    'C4 - G3 - | F4 - G3 - | C4 - E4 - | C4 - G3 -',
    voice: bar,
    at: 0.05,
    beat: beat,
    gain: 0.45,
  );
  return reverb(track, room: 0.45, wet: 0.1);
}

/// A xylophone bar struck by a hard mallet: a short, hollow tone with an
/// overtone a twelfth up, and the knock of the mallet.
Float64List _woodBar(Xorshift random, double frequency) {
  final sound = ring(
    [
      (frequency: frequency, amplitude: 1, decay: 0.3 * sqrt(523 / frequency)),
      (frequency: 3 * frequency, amplitude: 0.35, decay: 0.08),
      (frequency: 6.1 * frequency, amplitude: 0.1, decay: 0.025),
    ],
    1.2,
    attack: 0.0008,
  );
  final knock = Filter(
    .band,
    2500,
    q: 1.2,
  ).apply(noise(random, 0.01, decay: 0.002));
  mix(sound, knock, 0, gain: 0.5);
  return sound;
}

/// A fast video game tune in A minor: a square-wave lead, a bouncing
/// triangle bass and noise drums.
Float64List _videoGame() {
  final random = Xorshift(5);
  final track = silence(23);
  const beat = 0.4; // 150 beats a minute
  play(
    track,
    'A5/1 C6 A5 E6/1 D6 C6 | C6/1 A5 F5 A5 C6/1.5 | '
    'B5/1 D6 B5 G5/1 A5 B5 | G#5/1 B5/1 E6/2 | '
    'A5/1 C6 A5 E6/1 G6 E6 | F6/1 E6 D6 C6/1 A5/1 | '
    'B5 C6 D6/1 G5/1 B5 D6 | C6 B5 A5/2 E5/1 | '
    'E6/1 G6/1 E6 C6 D6 E6 | D6/1 B5/1 G5/1 B5 D6 | '
    'C6/1 A5/1 F5 A5 C6 F6 | E6 D6 C6 B5 D6/1 G5/1 | '
    'A5 C6 E6 A6 E6 C6 A5 C6 | B5 G#5 E5 G#5 A5/2',
    voice: _square,
    at: 0.05,
    beat: beat,
    unit: 0.5,
    gain: 0.5,
  );
  // The root of each bar's chord, bouncing between two octaves.
  const roots = [
    ('A2', 'A3'),
    ('F2', 'F3'),
    ('G2', 'G3'),
    ('E2', 'E3'),
    ('A2', 'A3'),
    ('F2', 'F3'),
    ('G2', 'G3'),
    ('A2', 'A3'),
    ('C3', 'C4'),
    ('G2', 'G3'),
    ('F2', 'F3'),
    ('G2', 'G3'),
    ('A2', 'A3'),
    ('E2', 'E3'),
  ];
  play(
    track,
    [for (final (low, high) in roots) List.filled(4, '$low $high').join(' ')]
        .join(' | '),
    voice: _triangle,
    at: 0.05,
    beat: beat,
    unit: 0.5,
    gain: 0.55,
  );
  // A kick on beats 1 and 3, a snare on 2 and 4, a hi-hat on every half
  // beat.
  for (var i = 0; i < 8 * roots.length; i++) {
    final at = 0.05 + i * beat / 2;
    if (i % 4 == 0) mix(track, _chipKick(), at, gain: 0.7);
    if (i % 4 == 2) mix(track, _chipSnare(random), at, gain: 0.35);
    mix(track, _chipHat(random), at, gain: i.isOdd ? 0.15 : 0.1);
  }
  return track;
}

/// A square-wave lead note, as old game consoles played them.
Float64List _square(double frequency, double seconds) =>
    _chip(Oscillator(.pulse, width: 0.25), frequency, seconds);

/// A triangle-wave bass note, as old game consoles played them.
Float64List _triangle(double frequency, double seconds) =>
    _chip(Oscillator(.triangle), frequency, seconds);

/// A note on [oscillator]: loud for a moment and then a little softer, with
/// vibrato on long notes and a short gap before the next note.
Float64List _chip(Oscillator oscillator, double frequency, double seconds) {
  final out = silence(seconds);
  final sounding = max(0, out.length - samplesIn(0.02));
  for (var i = 0; i < sounding; i++) {
    final t = i / sampleRate;
    final vibrato = t > 0.15 ? 1 + 0.008 * sin(2 * pi * 6 * t) : 1.0;
    final level = t < 0.03 ? 1.0 : 0.8;
    out[i] = level * oscillator.next(frequency * vibrato);
  }
  return out;
}

/// An 8-bit kick: a square wave that drops fast in pitch.
Float64List _chipKick() {
  final oscillator = Oscillator(.pulse);
  final out = silence(0.1);
  for (var i = 0; i < out.length; i++) {
    final t = i / sampleRate;
    out[i] = (1 - t / 0.1) * oscillator.next(55 + 165 * exp(-t / 0.02));
  }
  return out;
}

/// An 8-bit snare: a short burst of noise.
Float64List _chipSnare(Xorshift random) =>
    Filter(.high, 800).apply(noise(random, 0.15, decay: 0.045));

/// An 8-bit hi-hat: a very short, high hiss.
Float64List _chipHat(Xorshift random) =>
    Filter(.high, 7000).apply(noise(random, 0.05, decay: 0.012));

/// A bell tower: six bells ringing rounds, then "plain hunt" changes back
/// to rounds, with the usual pause after every second row.
Float64List _bellTower() {
  final random = Xorshift(6);
  final track = silence(24);
  // From the treble, the highest bell, down to the tenor: the top six notes
  // of C major.
  final bells = [
    for (final name in ['A5', 'G5', 'F5', 'E5', 'D5', 'C5'])
      _bell(random, note(name)),
  ];
  const rounds = [0, 1, 2, 3, 4, 5];
  const strike = 0.24;
  final rows = [rounds, rounds, ..._plainHunt(rounds), rounds];
  var at = 0.05;
  for (final (i, row) in rows.indexed) {
    for (final bell in row) {
      final time = at + random.between(-0.008, 0.008);
      mix(track, bells[bell], time, gain: random.between(0.8, 1));
      at += strike;
    }
    if (i.isOdd) at += strike;
  }
  return reverb(track, room: 0.85, damp: 0.35, wet: 0.3);
}

/// The rows of plain hunt from [rounds] until the bells are back in rounds:
/// neighbours swap places, in pairs from the first place and then in pairs
/// from the second.
List<List<int>> _plainHunt(List<int> rounds) {
  final rows = <List<int>>[];
  var row = rounds;
  do {
    row = [...row];
    for (var place = rows.length % 2; place + 1 < row.length; place += 2) {
      final swap = row[place];
      row[place] = row[place + 1];
      row[place + 1] = swap;
    }
    rows.add(row);
  } while (row.join() != rounds.join());
  return rows;
}

/// A church bell that strikes [nominal] Hz: the hum two octaves down, the
/// prime, the minor third that makes bells sound like bells, the fifth, the
/// nominal and a few higher partials. The hum is quieter than a real
/// bell's, which phone speakers can't play anyway.
Float64List _bell(Xorshift random, double nominal) {
  final sound = ring(
    [
      (frequency: 0.25 * nominal, amplitude: 0.2, decay: 3),
      (frequency: 0.5 * nominal, amplitude: 0.35, decay: 3),
      (frequency: 0.6 * nominal, amplitude: 0.4, decay: 3),
      (frequency: 0.75 * nominal, amplitude: 0.2, decay: 2.2),
      (frequency: nominal, amplitude: 1, decay: 2.2),
      (frequency: 1.5 * nominal, amplitude: 0.35, decay: 1.1),
      (frequency: 2 * nominal, amplitude: 0.2, decay: 0.7),
      (frequency: 2.6 * nominal, amplitude: 0.1, decay: 0.4),
    ],
    6,
    attack: 0.001,
  );
  final clang = Filter(
    .band,
    3000,
    q: 0.8,
  ).apply(noise(random, 0.02, decay: 0.004));
  mix(sound, clang, 0, gain: 0.3);
  return sound;
}

// Strong -------------------------------------------------------------------

/// Drums: a driving rock beat with tom fills, then four on the floor, and a
/// crash to end on.
Float64List _drums() {
  final random = Xorshift(7);
  final track = silence(24);
  final kit = {
    'kick': _kick(random),
    'snare': _snare(random),
    'hat': _hat(random, open: false),
    'open': _hat(random, open: true),
    'tom1': _tom(random, 'D3'),
    'tom2': _tom(random, 'A2'),
    'tom3': _tom(random, 'E2'),
    'crash': _crash(random),
  };
  // One character per sixteenth note: x plays, . rests.
  const rock = {
    'kick': 'x.......x.x.....',
    'snare': '....x.......x...',
    'hat': 'x.x.x.x.x.x.x.x.',
  };
  const push = {
    'kick': 'x.....x.x.......',
    'snare': '....x.......x..x',
    'hat': 'x.x.x.x.x.x.x...',
    'open': '..............x.',
  };
  const fill = {
    'kick': 'x.......x.......',
    'snare': '....x...xxxx....',
    'hat': 'x.x.x.x.........',
    'tom1': '............xx..',
    'tom2': '..............x.',
    'tom3': '...............x',
  };
  const roll = {
    'kick': 'x.....x.x.......',
    'snare': '....x.......x...',
    'hat': 'x.x.x.x.........',
    'tom1': '........xx......',
    'tom2': '..........xx....',
    'tom3': '............xxxx',
  };
  const drive = {
    'kick': 'x...x...x...x...',
    'snare': '....x.......x...',
    'hat': 'xxxxxxxxxxxxxxxx',
  };
  const end = {'kick': 'x...............'};
  const bars = [rock, rock, push, fill, rock, push, rock, roll];
  const sixteenth = 0.125; // 120 beats a minute
  for (final (bar, drums) in [...bars, drive, drive, drive, end].indexed) {
    final start = 0.05 + 16 * sixteenth * bar;
    if (bar % 4 == 0 || drums == end) {
      mix(track, kit['crash']!, start, gain: 0.5);
    }
    for (final MapEntry(key: drum, value: steps) in drums.entries) {
      for (var step = 0; step < steps.length; step++) {
        if (steps[step] != 'x') continue;
        final gain = switch (drum) {
          'hat' => step.isEven ? 0.5 : 0.25,
          'open' => 0.4,
          _ => 0.8,
        };
        final time = start + step * sixteenth + random.between(0, 0.004);
        mix(track, kit[drum]!, time, gain: gain);
      }
    }
  }
  saturate(track, 2);
  return reverb(track, room: 0.3, wet: 0.08);
}

/// A kick drum: a low thump that drops in pitch, with a click on top.
Float64List _kick(Xorshift random) {
  final out = silence(0.5);
  var phase = 0.0;
  for (var i = 0; i < out.length; i++) {
    final t = i / sampleRate;
    phase += 2 * pi * (48 + 110 * exp(-t / 0.035)) / sampleRate;
    out[i] = exp(-t / 0.22) * sin(phase);
  }
  final click = Filter(.high, 1500).apply(noise(random, 0.01, decay: 0.002));
  mix(out, click, 0, gain: 0.4);
  return out;
}

/// A snare drum: a short tone for the drum head and a burst of noise for
/// the wires.
Float64List _snare(Xorshift random) {
  final out = ring([
    (frequency: 185, amplitude: 0.7, decay: 0.06),
    (frequency: 330, amplitude: 0.35, decay: 0.04),
  ], 0.3);
  final wires = Filter(
    .band,
    3500,
    q: 0.6,
  ).apply(noise(random, 0.3, decay: 0.09));
  mix(out, wires, 0, gain: 0.9);
  return out;
}

/// A hi-hat: a high hiss, short when closed and long when [open].
Float64List _hat(Xorshift random, {required bool open}) => Filter(
  .high,
  7000,
).apply(noise(random, open ? 0.45 : 0.08, decay: open ? 0.2 : 0.03));

/// A tom-tom tuned to [name]: a round tone that sinks a little.
Float64List _tom(Xorshift random, String name) {
  final frequency = note(name);
  final out = silence(0.6);
  var phase = 0.0;
  for (var i = 0; i < out.length; i++) {
    final t = i / sampleRate;
    phase += 2 * pi * frequency * (1 + 0.3 * exp(-t / 0.05)) / sampleRate;
    out[i] = exp(-t / 0.25) * sin(phase);
  }
  final skin = Filter(
    .band,
    1200,
    q: 0.7,
  ).apply(noise(random, 0.05, decay: 0.01));
  mix(out, skin, 0, gain: 0.3);
  return out;
}

/// A crash cymbal: a long, bright wash of noise.
Float64List _crash(Xorshift random) =>
    Filter(.high, 4500).apply(noise(random, 2.2, decay: 0.8));

/// An old alarm clock: a hammer rattling between two bells about 22 times a
/// second, in bursts, the way a wind-up clock rings.
Float64List _alarmClock() {
  final random = Xorshift(8);
  final track = silence(24);
  // When each bell is struck, in samples, and how hard.
  final strikes = [<(int, double)>[], <(int, double)>[]];
  for (var burst = 0.03; burst < 23.2; burst += 2.3) {
    var time = burst;
    var bell = 0;
    while (time < min(burst + 1.8, 23.4)) {
      strikes[bell].add((samplesIn(time), random.between(0.7, 1)));
      time += 1 / 22 + random.between(-0.002, 0.002);
      bell = 1 - bell;
    }
  }
  const bells = <List<Partial>>[
    [
      (frequency: 2240, amplitude: 1, decay: 0.9),
      (frequency: 3190, amplitude: 0.6, decay: 0.55),
      (frequency: 4980, amplitude: 0.45, decay: 0.3),
      (frequency: 6880, amplitude: 0.28, decay: 0.18),
    ],
    [
      (frequency: 2510, amplitude: 1, decay: 0.9),
      (frequency: 3560, amplitude: 0.6, decay: 0.55),
      (frequency: 5390, amplitude: 0.4, decay: 0.3),
      (frequency: 7310, amplitude: 0.25, decay: 0.18),
    ],
  ];
  for (final (bell, partials) in bells.indexed) {
    final hits = strikes[bell];
    for (final (:frequency, :amplitude, :decay) in partials) {
      // As in `ring`, but every strike pushes the turning pointer again,
      // so the bell keeps ringing from one strike into the next.
      final angle = 2 * pi * frequency / sampleRate;
      final shrink = exp(-1 / (decay * sampleRate));
      final turnX = shrink * cos(angle);
      final turnY = shrink * sin(angle);
      var x = 0.0;
      var y = 0.0;
      var next = 0;
      for (var i = 0; i < track.length; i++) {
        while (next < hits.length && hits[next].$1 <= i) {
          x += amplitude * hits[next].$2;
          next++;
        }
        track[i] += y;
        final nextX = x * turnX - y * turnY;
        y = x * turnY + y * turnX;
        x = nextX;
      }
    }
  }
  // The clatter of the hammer.
  for (final (at, strength) in strikes.expand((hits) => hits)) {
    final tick = Filter(
      .band,
      1500,
      q: 1.5,
    ).apply(noise(random, 0.006, decay: 0.0015));
    mix(track, tick, at / sampleRate, gain: 0.25 * strength);
  }
  saturate(track, 1.5);
  return reverb(track, room: 0.3, wet: 0.08);
}

/// A fanfare in B-flat major: two trumpets in harmony over a trombone, with
/// timpani.
Float64List _fanfare() {
  final random = Xorshift(9);
  final track = silence(24);
  const beat = 0.5; // 120 beats a minute
  play(
    track,
    'F4/.75 F4/.25 Bb4 D5 F5 | Eb5/.5 D5/.5 C5 F5/2 | '
    'F4/.75 F4/.25 C5 Eb5 G5 | F5/.5 Eb5/.5 D5 Bb4/2 | '
    'D5/.75 D5/.25 G5 F5 Eb5 | D5 C5 F5/2 | '
    'F5/.75 F5/.25 Bb5 A5/.5 G5/.5 F5 | G5 Eb5 C5/2 | '
    'Bb4/.75 Bb4/.25 D5 F5 Bb5 | A5/.5 Bb5/.5 C6 A5 F5 | Bb5/6',
    voice: _trumpet,
    at: 0.05,
    beat: beat,
    gain: 0.5,
  );
  play(
    track,
    'F4/.75 F4/.25 F4 Bb4 D5 | C5/.5 Bb4/.5 A4 C5/2 | '
    'F4/.75 F4/.25 G4 C5 Eb5 | D5/.5 C5/.5 Bb4 F4/2 | '
    'Bb4/.75 Bb4/.25 D5 C5 A4 | Bb4 A4 C5/2 | '
    'D5/.75 D5/.25 F5 F5/.5 Eb5/.5 D5 | Eb5 C5 A4/2 | '
    'F4/.75 F4/.25 Bb4 D5 F5 | F5/.5 F5/.5 A5 F5 C5 | F5/6',
    voice: _trumpet,
    at: 0.05,
    beat: beat,
    gain: 0.32,
  );
  play(
    track,
    'Bb2/4 | F2/4 | C3/4 | Bb2/4 | G2/2 F2/2 | F2/4 | '
    'Bb2/2 F2/2 | Eb3/2 F2/2 | Bb2/4 | F2/4 | Bb2/6',
    voice: _trombone,
    at: 0.05,
    beat: beat,
    gain: 0.4,
  );
  // Timpani: a stroke at the start of every second bar, and rolls into the
  // last line and under the last note. A roll's strokes ring into each
  // other, so it plays softer.
  Float64List drum(double frequency, double _) => _timpani(random, frequency);
  for (final (strokes, gain) in [
    ('Bb2/8 F2/8 Bb2/8 F2/4 -/4 Bb2/8 -/6', 0.45),
    ('-/28 F2~/4 -/8 Bb2~/6', 0.1),
  ]) {
    play(
      track,
      strokes,
      voice: drum,
      at: 0.05,
      beat: beat,
      gain: gain,
      rollEvery: 0.07,
    );
  }
  // Tames the timpani's peaks, so the brass can be as loud as the other
  // strong sounds.
  saturate(track, 1.5);
  return reverb(track, room: 0.75, damp: 0.35);
}

/// A trumpet note.
Float64List _trumpet(double frequency, double seconds) =>
    _brass(frequency, seconds, brightness: 7);

/// A trombone note: darker than a trumpet.
Float64List _trombone(double frequency, double seconds) =>
    _brass(frequency, seconds, brightness: 5);

/// A brass note: two sawtooth waves through a filter that opens on the
/// attack and then settles, with a small scoop up to the pitch and vibrato
/// on long notes. [brightness] sets how far the filter opens.
Float64List _brass(
  double frequency,
  double seconds, {
  required double brightness,
}) {
  final saws = [Oscillator(.saw), Oscillator(.saw)];
  final filter = Filter(.low, frequency, q: 0.9);
  const release = 0.08;
  final out = silence(seconds + release);
  for (var i = 0; i < out.length; i++) {
    final t = i / sampleRate;
    final scoop = 1 - 0.025 * exp(-t / 0.03);
    final vibrato =
        1 + 0.005 * sin(2 * pi * 5.5 * t) * (t - 0.25).clamp(0, 0.2) / 0.2;
    final pitch = frequency * scoop * vibrato;
    final attack = min<double>(1, t / 0.025);
    final ending = t < seconds
        ? 1
        : max<double>(0, 1 - (t - seconds) / release);
    final level = attack * ending * (0.85 + 0.25 * exp(-t / 0.06));
    filter.cutoff =
        frequency * (1 + brightness * level * (0.6 + 0.4 * exp(-t / 0.12)));
    final wave = saws[0].next(pitch) + saws[1].next(1.004 * pitch);
    out[i] = level * filter.process(0.5 * wave);
  }
  return out;
}

/// A timpani stroke: a deep drum whose overtones are nearly in tune.
Float64List _timpani(Xorshift random, double frequency) {
  final sound = ring(
    [
      (frequency: frequency, amplitude: 1, decay: 1),
      (frequency: 1.5 * frequency, amplitude: 0.6, decay: 0.7),
      (frequency: 1.98 * frequency, amplitude: 0.4, decay: 0.5),
      (frequency: 2.44 * frequency, amplitude: 0.25, decay: 0.35),
    ],
    2.5,
    attack: 0.003,
  );
  final thump = Filter(.low, 600).apply(noise(random, 0.08, decay: 0.02));
  mix(sound, thump, 0, gain: 0.5);
  return sound;
}
