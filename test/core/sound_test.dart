import 'package:flutter_test/flutter_test.dart';
import 'package:shuffle_alarm/core/sound.dart';

Sound _sound({
  String id = 'lofi-01',
  String title = 'Slow Sunrise',
  SoundSource source = .builtin,
  String genre = 'lofi',
  Intensity intensity = .gentle,
  Duration duration = const Duration(seconds: 29),
  Duration clipStart = Duration.zero,
}) => Sound(
  id: id,
  title: title,
  source: source,
  genre: genre,
  intensity: intensity,
  duration: duration,
  clipStart: clipStart,
);

void main() {
  test('plays from the beginning unless a clip start is set', () {
    final sound = Sound(
      id: 'lofi-01',
      title: 'Slow Sunrise',
      source: .builtin,
      genre: 'lofi',
      intensity: .gentle,
      duration: const Duration(seconds: 29),
    );

    expect(sound.clipStart, Duration.zero);
  });

  test('a song can start its clip anywhere inside it', () {
    final song = _sound(
      source: .user,
      duration: const Duration(minutes: 3, seconds: 45),
      clipStart: const Duration(minutes: 3, seconds: 44),
    );

    expect(song.clipStart, const Duration(minutes: 3, seconds: 44));
  });

  test('rejects a sound without length', () {
    for (final duration in [Duration.zero, const Duration(seconds: -1)]) {
      expect(() => _sound(duration: duration), throwsAssertionError);
    }
  });

  test('rejects a clip start outside the sound', () {
    for (final clipStart in [
      const Duration(milliseconds: -1),
      const Duration(seconds: 29),
      const Duration(seconds: 40),
    ]) {
      expect(() => _sound(clipStart: clipStart), throwsAssertionError);
    }
  });

  test('intensity rises from gentle (1) to strong (3)', () {
    expect(Intensity.values, [
      Intensity.gentle,
      Intensity.medium,
      Intensity.strong,
    ]);
    expect(Intensity.values.map((intensity) => intensity.level), [1, 2, 3]);
  });

  test('equals a sound with the same values', () {
    expect(_sound(), _sound());
    expect(_sound().hashCode, _sound().hashCode);
  });

  test('differs when any value differs', () {
    final sound = _sound();
    final others = [
      _sound(id: 'lofi-02'),
      _sound(title: 'Bright Sunrise'),
      _sound(source: .voice),
      _sound(genre: 'jazz'),
      _sound(intensity: .strong),
      _sound(duration: const Duration(seconds: 28)),
      _sound(clipStart: const Duration(seconds: 1)),
    ];

    for (final other in others) {
      expect(other, isNot(sound));
    }
  });
}
