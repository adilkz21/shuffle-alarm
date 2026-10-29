// Checks the sound library bundled with the app: the manifest, the audio
// files and the product rules for them (CLAUDE.md, docs/DECISIONS.md D14).
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shuffle_alarm/core/sound.dart';
import 'package:shuffle_alarm/data/sound_library.dart';

/// What a WAV file says about itself, and its samples.
typedef _Wav = ({
  int format,
  int channels,
  int sampleRate,
  int bits,
  Int16List samples,
});

/// The format and samples of the WAV file [bytes], read chunk by chunk.
_Wav _wavOf(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  String tag(int at) => String.fromCharCodes(bytes, at, at + 4);
  expect([tag(0), tag(8)], ['RIFF', 'WAVE']);
  var (format, channels, sampleRate, bits) = (0, 0, 0, 0);
  var samples = Int16List(0);
  for (var at = 12; at + 8 <= bytes.length;) {
    final size = data.getUint32(at + 4, .little);
    final body = at + 8;
    switch (tag(at)) {
      case 'fmt ':
        format = data.getUint16(body, .little);
        channels = data.getUint16(body + 2, .little);
        sampleRate = data.getUint32(body + 4, .little);
        bits = data.getUint16(body + 14, .little);
      case 'data':
        samples = Int16List.sublistView(
          Uint8List.fromList(bytes.sublist(body, body + size)),
        );
    }
    at = body + size + size % 2;
  }
  return (
    format: format,
    channels: channels,
    sampleRate: sampleRate,
    bits: bits,
    samples: samples,
  );
}

/// The loudness of [wav] in 50-ms windows: the root mean square of each.
List<double> _windowLevels(_Wav wav) {
  final window = wav.sampleRate ~/ 20;
  return [
    for (var start = 0; start + window <= wav.samples.length; start += window)
      sqrt(
        wav.samples
                .sublist(start, start + window)
                .fold<double>(0, (sum, sample) => sum + sample * sample) /
            window,
      ),
  ];
}

/// [decibels] below full scale, as a 16-bit sample value.
double _level(double decibels) => 32767 * pow(10, decibels / 20).toDouble();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late final SoundLibrary library;
  late final Map<String, _Wav> wavs;

  setUpAll(() async {
    library = await loadSoundLibrary(rootBundle.loadString);
    wavs = {
      for (final LibraryEntry(:asset) in library.entries)
        asset: _wavOf(File(asset).readAsBytesSync()),
    };
  });

  /// The placeholder sounds that tool/make_placeholder_sounds.dart makes.
  List<LibraryEntry> placeholders() => [
    for (final entry in library.entries)
      if (entry.sound.genre == 'placeholder') entry,
  ];

  test('the manifest loads without problems', () {
    expect(library.problems, isEmpty);
    expect(library.entries, isNotEmpty);
  });

  test('there are nine placeholder sounds, three of each intensity', () {
    final levels = [
      for (final LibraryEntry(:sound) in placeholders()) sound.intensity.level,
    ];

    expect(levels, hasLength(9));
    for (final level in [1, 2, 3]) {
      expect(levels.where((each) => each == level), hasLength(3));
    }
  });

  test('the placeholder sounds are our own, so they need no credit', () {
    for (final entry in placeholders()) {
      expect(entry.license, 'original', reason: entry.sound.id);
      expect(entry.artist, 'Shuffle Alarm', reason: entry.sound.id);
      expect(entry.attribution, isEmpty, reason: entry.sound.id);
    }
  });

  test('titles share no word, so they are easy to tell apart', () {
    // "Which sound is playing?" shows titles to pick from, half-awake.
    final words = [
      for (final LibraryEntry(:sound) in library.entries)
        ...sound.title.toLowerCase().split(' '),
    ];

    expect(words.toSet(), hasLength(words.length));
  });

  test('every audio file in assets/library is in the manifest', () {
    // CLAUDE.md: every bundled audio file needs an entry. And every entry
    // needs its file.
    const audio = {'.wav', '.caf', '.aiff', '.mp3', '.m4a', '.ogg', '.flac'};
    final files = {
      for (final file in Directory('assets/library').listSync(recursive: true))
        if (file is File &&
            audio.any((extension) => file.path.endsWith(extension)))
          file.path.replaceAll(r'\', '/'),
    };

    expect(files, {for (final entry in library.entries) entry.asset});
  });

  test('every file is bundled with the app', () async {
    for (final LibraryEntry(:asset) in library.entries) {
      final bytes = await rootBundle.load(asset);
      expect(bytes.lengthInBytes, File(asset).lengthSync(), reason: asset);
    }
  });

  test('every file is a 16-bit mono PCM WAV', () {
    // Every platform plays it, and so does iOS AlarmKit (D14).
    for (final MapEntry(key: asset, value: wav) in wavs.entries) {
      expect(asset, endsWith('.wav'));
      expect((wav.format, wav.channels, wav.bits), (1, 1, 16), reason: asset);
    }
  });

  test('every file lasts as long as the manifest says, 1 to 29 s', () {
    // iOS AlarmKit only plays alarm sounds shorter than 30 s, and the ring
    // skips clips under a second (D9, D13).
    for (final LibraryEntry(:sound, :asset) in library.entries) {
      final wav = wavs[asset]!;
      final length = Duration(
        microseconds: wav.samples.length * 1000000 ~/ wav.sampleRate,
      );

      expect(
        (length - sound.duration).abs(),
        lessThan(const Duration(milliseconds: 1)),
        reason: asset,
      );
      expect(length, greaterThanOrEqualTo(const Duration(seconds: 1)));
      expect(length, lessThanOrEqualTo(const Duration(seconds: 29)));
    }
  });

  test('no clip distorts, and each starts and ends without a click', () {
    for (final MapEntry(key: asset, value: wav) in wavs.entries) {
      final peak = wav.samples.fold(
        0,
        (peak, sample) => max(peak, sample.abs()),
      );

      expect(peak, lessThanOrEqualTo(_level(-1) + 1), reason: asset);
      expect(peak, greaterThan(_level(-12)), reason: '$asset is too quiet');
      expect(wav.samples.first.abs(), lessThan(_level(-50)), reason: asset);
      expect(wav.samples.last.abs(), lessThan(_level(-50)), reason: asset);
    }
  });

  test('no clip goes quiet for a second or more', () {
    // An alarm must not seem to stop, and "Catch the change" counts on the
    // switch to the next sound being the only break.
    for (final MapEntry(key: asset, value: wav) in wavs.entries) {
      var quiet = 0;
      var longest = 0;
      for (final level in _windowLevels(wav)) {
        quiet = level < _level(-50) ? quiet + 1 : 0;
        longest = max(longest, quiet);
      }

      expect(
        longest * 50,
        lessThan(1000),
        reason: '$asset: ${longest * 50} ms',
      );
    }
  });

  test('gentle sounds are softer than medium ones, and those than strong', () {
    // The level of a sound: the mean loudness of its windows that aren't
    // near silence.
    double levelOf(_Wav wav) {
      final heard = _windowLevels(wav).where((level) => level > _level(-50));
      return heard.reduce((a, b) => a + b) / heard.length;
    }

    final byIntensity = {
      for (final intensity in Intensity.values)
        intensity:
            [
              for (final LibraryEntry(:sound, :asset) in placeholders())
                if (sound.intensity == intensity) levelOf(wavs[asset]!),
            ].reduce((a, b) => a + b) /
            3,
    };

    expect(
      byIntensity[Intensity.gentle],
      lessThan(byIntensity[Intensity.medium]!),
    );
    expect(
      byIntensity[Intensity.medium],
      lessThan(byIntensity[Intensity.strong]!),
    );
  });
}
