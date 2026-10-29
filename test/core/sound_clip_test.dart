import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shuffle_alarm/core/sound.dart';
import 'package:shuffle_alarm/core/sound_clip.dart';

Sound _sound({
  String id = 'lofi-01',
  SoundSource source = .builtin,
  Duration duration = const Duration(seconds: 29),
  Duration clipStart = Duration.zero,
}) => Sound(
  id: id,
  title: 'Slow Sunrise',
  source: source,
  genre: 'lofi',
  intensity: .gentle,
  duration: duration,
  clipStart: clipStart,
);

/// The clips of 10 000 sounds from every source, up to 5 min long, with
/// their clip start anywhere inside them. The seed is fixed, so every run
/// checks the same sounds.
List<SoundClip> _clipsOfRandomSounds() {
  final random = Random(1);
  return [
    for (var i = 0; i < 10000; i++)
      SoundClip.of(_randomSound(random, 'random-$i')),
  ];
}

Sound _randomSound(Random random, String id) {
  final duration = Duration(
    microseconds: 1 + random.nextInt(const Duration(minutes: 5).inMicroseconds),
  );
  return _sound(
    id: id,
    source: SoundSource.values[random.nextInt(SoundSource.values.length)],
    duration: duration,
    clipStart: Duration(microseconds: random.nextInt(duration.inMicroseconds)),
  );
}

void main() {
  test('a sound plays at most 30 s, or 29 s when it is bundled', () {
    expect(SoundClip.maxLength, const Duration(seconds: 30));
    expect(SoundClip.maxBundledLength, const Duration(seconds: 29));
    expect(SoundClip.maxLengthFor(.builtin), SoundClip.maxBundledLength);
    expect(SoundClip.maxLengthFor(.user), SoundClip.maxLength);
    expect(SoundClip.maxLengthFor(.voice), SoundClip.maxLength);
  });

  group('a bundled sound', () {
    test('plays whole when its file is 29 s or shorter', () {
      for (final duration in const [
        Duration(seconds: 1),
        Duration(seconds: 20),
        Duration(seconds: 29),
      ]) {
        final clip = SoundClip.of(_sound(duration: duration));

        expect(clip.start, Duration.zero);
        expect(clip.length, duration);
        expect(clip.end, duration);
      }
    });

    test('is cut to 29 s when its file is longer', () {
      for (final duration in const [
        Duration(seconds: 29, milliseconds: 1),
        Duration(seconds: 30),
        Duration(seconds: 45),
      ]) {
        final clip = SoundClip.of(_sound(duration: duration));

        expect(clip.start, Duration.zero);
        expect(clip.length, const Duration(seconds: 29));
      }
    });
  });

  group('a song or voice message', () {
    test('plays whole when it is 30 s or shorter', () {
      for (final source in const [SoundSource.user, SoundSource.voice]) {
        for (final duration in const [
          Duration(seconds: 1),
          Duration(seconds: 12),
          Duration(seconds: 30),
        ]) {
          final clip = SoundClip.of(_sound(source: source, duration: duration));

          expect(clip.start, Duration.zero);
          expect(clip.length, duration);
        }
      }
    });

    test('is cut to 30 s when it is longer', () {
      for (final (source, duration) in const [
        (SoundSource.user, Duration(seconds: 30, milliseconds: 1)),
        (SoundSource.user, Duration(minutes: 3, seconds: 45)),
        (SoundSource.voice, Duration(seconds: 45)),
      ]) {
        final clip = SoundClip.of(_sound(source: source, duration: duration));

        expect(clip.start, Duration.zero);
        expect(clip.length, const Duration(seconds: 30));
      }
    });

    test('plays 30 s from its clip start', () {
      final clip = SoundClip.of(
        _sound(
          source: .user,
          duration: const Duration(minutes: 3, seconds: 45),
          clipStart: const Duration(minutes: 1),
        ),
      );

      expect(clip.start, const Duration(minutes: 1));
      expect(clip.length, const Duration(seconds: 30));
      expect(clip.end, const Duration(minutes: 1, seconds: 30));
    });

    test('stops at the end of its file', () {
      final clip = SoundClip.of(
        _sound(
          source: .user,
          duration: const Duration(minutes: 3, seconds: 45),
          clipStart: const Duration(minutes: 3, seconds: 30),
        ),
      );

      expect(clip.start, const Duration(minutes: 3, seconds: 30));
      expect(clip.length, const Duration(seconds: 15));
      expect(clip.end, const Duration(minutes: 3, seconds: 45));
    });
  });

  group('for 10 000 random sounds', () {
    // Checks the numbers themselves, not the constants, so changing a
    // constant can't quietly break the product rule.
    test('no clip is over 30 s, and no bundled clip over 29 s', () {
      final clips = _clipsOfRandomSounds();

      expect(
        clips.where((clip) => clip.length > const Duration(seconds: 30)),
        isEmpty,
      );
      expect(
        clips.where(
          (clip) =>
              clip.sound.source == .builtin &&
              clip.length > const Duration(seconds: 29),
        ),
        isEmpty,
      );
    });

    test('every clip starts at its clip start and ends inside its file', () {
      expect(
        _clipsOfRandomSounds().where(
          (clip) =>
              clip.start != clip.sound.clipStart ||
              clip.length <= Duration.zero ||
              clip.end > clip.sound.duration,
        ),
        isEmpty,
      );
    });

    test('every clip plays to the end of its file or to the limit', () {
      expect(
        _clipsOfRandomSounds().where(
          (clip) =>
              clip.end != clip.sound.duration &&
              clip.length != SoundClip.maxLengthFor(clip.sound.source),
        ),
        isEmpty,
      );
    });
  });

  test('equals the clip of an equal sound', () {
    expect(SoundClip.of(_sound()), SoundClip.of(_sound()));
    expect(SoundClip.of(_sound()).hashCode, SoundClip.of(_sound()).hashCode);
  });

  test('differs when the sound differs', () {
    final clip = SoundClip.of(_sound());
    final others = [
      _sound(id: 'lofi-02'),
      _sound(duration: const Duration(seconds: 28)),
      _sound(clipStart: const Duration(seconds: 1)),
    ];

    for (final other in others) {
      expect(SoundClip.of(other), isNot(clip));
    }
  });
}
