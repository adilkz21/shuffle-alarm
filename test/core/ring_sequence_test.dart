import 'dart:isolate';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shuffle_alarm/core/alarm.dart';
import 'package:shuffle_alarm/core/ring_sequence.dart';
import 'package:shuffle_alarm/core/sound.dart';
import 'package:shuffle_alarm/core/sound_clip.dart';

Alarm _alarm({Set<String> genres = const {}}) =>
    Alarm(id: 'a1', time: const AlarmTime(6, 30), genres: genres);

Sound _sound(
  String id, {
  String genre = 'lofi',
  SoundSource source = .builtin,
  Duration duration = const Duration(seconds: 29),
  Duration clipStart = Duration.zero,
}) => Sound(
  id: id,
  title: 'Slow Sunrise',
  source: source,
  genre: genre,
  intensity: .gentle,
  duration: duration,
  clipStart: clipStart,
);

/// [count] lofi sounds with the ids `sound-00`, `sound-01` and so on.
List<Sound> _pool(
  int count, {
  SoundSource source = .builtin,
  Duration duration = const Duration(seconds: 29),
}) => [
  for (var i = 0; i < count; i++)
    _sound(
      'sound-${i.toString().padLeft(2, '0')}',
      source: source,
      duration: duration,
    ),
];

/// The ids of the sounds [clips] play, in order.
List<String> _ids(Iterable<SoundClip> clips) => [
  for (final clip in clips) clip.sound.id,
];

/// How long [clips] last together.
Duration _lengthOf(Iterable<SoundClip> clips) =>
    clips.fold(Duration.zero, (length, clip) => length + clip.length);

/// The longest a clip of [sound] may be: 29 s when it is bundled, else 30 s.
Duration _limitOf(Sound sound) => sound.source == .builtin
    ? const Duration(seconds: 29)
    : const Duration(seconds: 30);

/// The ids of the sounds in [pool] that [alarm] can play: sounds of its
/// genres whose clip lasts at least a second.
Set<String> _playable(Alarm alarm, Iterable<Sound> pool) => {
  for (final sound in pool)
    if (alarm.playsGenre(sound.genre) &&
        SoundClip.of(sound).length >= const Duration(seconds: 1))
      sound.id,
};

const _genres = ['lofi', 'rock', 'nature'];

/// A random alarm, its pool and the clips of its ring with its seed.
typedef _Run = ({
  int seed,
  Alarm alarm,
  List<Sound> pool,
  List<SoundClip> clips,
});

/// The rings of 1000 random alarms, each with its own seed and a pool of up
/// to 12 sounds of 3 genres. The seeds are fixed, so every run checks the
/// same rings.
List<_Run> _randomRuns() => [
  for (var seed = 0; seed < 1000; seed++) _randomRun(seed),
];

_Run _randomRun(int seed) {
  final random = Random(seed);
  final alarm = _alarm(
    genres: {
      for (final genre in _genres)
        if (random.nextBool()) genre,
    },
  );
  final pool = List.generate(
    random.nextInt(13),
    (i) => _randomSound(random, 'sound-$i'),
  );
  return (
    seed: seed,
    alarm: alarm,
    pool: pool,
    clips: buildRingSequence(alarm, pool, seed),
  );
}

/// A sound of any genre and source, up to 3 min long, with its clip start
/// anywhere inside it. About one sound in five is shorter than a second.
Sound _randomSound(Random random, String id) {
  final maxDuration = random.nextInt(5) == 0
      ? const Duration(seconds: 1)
      : const Duration(minutes: 3);
  final duration = Duration(
    microseconds: 1 + random.nextInt(maxDuration.inMicroseconds - 1),
  );
  return _sound(
    id,
    genre: _genres[random.nextInt(_genres.length)],
    source: SoundSource.values[random.nextInt(SoundSource.values.length)],
    duration: duration,
    clipStart: random.nextBool()
        ? Duration.zero
        : Duration(microseconds: random.nextInt(duration.inMicroseconds)),
  );
}

/// The ring of an alarm whose every clip is under a second. A top-level
/// function, so it can run in its own isolate.
List<SoundClip> _ringOfShortClips() => buildRingSequence(
  _alarm(),
  _pool(5, duration: const Duration(milliseconds: 999)),
  1,
);

void main() {
  group('in 1000 random rings', () {
    late final List<_Run> runs;

    setUpAll(() async {
      // Some pools have no clip of a second or longer. The rings are built
      // in their own isolate, so a loop that never ends fails these tests
      // instead of hanging the whole run.
      runs = await Isolate.run(_randomRuns)
          .timeout(const Duration(seconds: 20));
    });

    test('every clip is the whole clip of a sound in the pool', () {
      // The clip rule cuts each sound, and the ring cuts no clip further,
      // not even the last one.
      expect([
        for (final (:seed, alarm: _, :pool, :clips) in runs)
          for (final (i, clip) in clips.indexed)
            if (!pool.contains(clip.sound) || clip != SoundClip.of(clip.sound))
              'seed $seed, turn ${i + 1}: $clip',
      ], isEmpty);
    });

    // Checks the numbers themselves, not the constants, so changing a
    // constant can't quietly break the product rule.
    test('no clip is over its limit or under a second', () {
      expect([
        for (final (:seed, alarm: _, pool: _, :clips) in runs)
          for (final (i, clip) in clips.indexed)
            if (clip.length > _limitOf(clip.sound) ||
                clip.length < const Duration(seconds: 1))
              'seed $seed, turn ${i + 1}: $clip',
      ], isEmpty);
    });

    test("only sounds of the alarm's genres play", () {
      expect([
        for (final (:seed, :alarm, pool: _, :clips) in runs)
          for (final (i, clip) in clips.indexed)
            if (alarm.genres.isNotEmpty &&
                !alarm.genres.contains(clip.sound.genre))
              'seed $seed, turn ${i + 1}: ${clip.sound.genre}',
      ], isEmpty);
    });

    test('no sound plays twice in a row', () {
      // Unless the alarm can play only one sound: then it plays every turn.
      expect([
        for (final (:seed, :alarm, :pool, :clips) in runs)
          if (_playable(alarm, pool).length > 1)
            for (var i = 1; i < clips.length; i++)
              if (clips[i].sound.id == clips[i - 1].sound.id)
                'seed $seed, turn ${i + 1}: ${clips[i].sound.id}',
      ], isEmpty);
    });

    test('every sound the alarm can play has its turn in the first round', () {
      final wrong = <String>[];
      for (final (:seed, :alarm, :pool, :clips) in runs) {
        final playable = _playable(alarm, pool);
        final firstRound = _ids(clips.take(playable.length));
        if (!const UnorderedIterableEquality<String>().equals(
          firstRound,
          playable,
        )) {
          wrong.add('seed $seed: $firstRound, can play $playable');
        }
      }
      expect(wrong, isEmpty);
    });

    test('the clips cover the cap, and only the last one runs past it', () {
      const cap = Duration(minutes: 10);
      expect([
        for (final (:seed, alarm: _, pool: _, :clips) in runs)
          if (clips.isNotEmpty &&
              (_lengthOf(clips) < cap ||
                  _lengthOf(clips) - clips.last.length >= cap))
            'seed $seed: ${_lengthOf(clips)}, last ${clips.last.length}',
      ], isEmpty);
    });

    test('a ring is empty only when the alarm can play none of its sounds', () {
      expect([
        for (final (:seed, :alarm, :pool, :clips) in runs)
          if (clips.isEmpty != _playable(alarm, pool).isEmpty)
            'seed $seed: ${clips.length} clips',
      ], isEmpty);
    });

    test('the same seed gives the same clips, whatever the pool order', () {
      for (final (:seed, :alarm, :pool, :clips) in runs) {
        expect(
          buildRingSequence(alarm, pool, seed),
          clips,
          reason: 'seed $seed',
        );
        expect(
          buildRingSequence(alarm, pool.reversed, seed),
          clips,
          reason: 'seed $seed, pool reversed',
        );
      }
    });
  });

  test('an empty pool gives no clips', () {
    expect(buildRingSequence(_alarm(), const [], 1), isEmpty);
  });

  test('an alarm plays only its genres, or every genre when it has none', () {
    final pool = [
      _sound('lofi-01'),
      _sound('rock-01', genre: 'rock'),
      _sound('nature-01', genre: 'nature'),
    ];
    Set<String> genresOf(Alarm alarm) => {
      for (final clip in buildRingSequence(alarm, pool, 1)) clip.sound.genre,
    };

    expect(genresOf(_alarm(genres: {'lofi', 'nature'})), {'lofi', 'nature'});
    expect(genresOf(_alarm()), {'lofi', 'rock', 'nature'});
    expect(genresOf(_alarm(genres: {'jazz'})), isEmpty);
  });

  test('a clip under a second is skipped, a clip of a second plays', () {
    final pool = [
      _sound('short', duration: const Duration(milliseconds: 999)),
      _sound('second', duration: const Duration(seconds: 1)),
      // A long file, but its clip starts 999 ms before the end.
      _sound(
        'late-start',
        source: .user,
        duration: const Duration(minutes: 3),
        clipStart: const Duration(minutes: 2, seconds: 59, milliseconds: 1),
      ),
      _sound('whole'),
    ];

    expect(_ids(buildRingSequence(_alarm(), pool, 1)).toSet(), {
      'second',
      'whole',
    });
  });

  test('skipped sounds never make a sound play twice in a row', () {
    // A bag that held the skipped sounds too could end a round with one of
    // them and open the next round with the sound played just before it.
    const short = Duration(milliseconds: 500);
    final pool = [
      _sound('a'),
      _sound('b'),
      for (final id in ['x', 'y', 'z']) _sound(id, duration: short),
    ];

    for (var seed = 0; seed < 100; seed++) {
      final ids = _ids(buildRingSequence(_alarm(), pool, seed));
      expect(ids.toSet(), {'a', 'b'});
      for (var i = 1; i < ids.length; i++) {
        expect(ids[i], isNot(ids[i - 1]), reason: 'seed $seed, turn ${i + 1}');
      }
    }
  });

  test('a pool where every clip is under a second gives no clips', () async {
    // Sound's asserts stop tests from making an empty clip; a clip under a
    // second is skipped the same way. It runs in its own isolate, so a loop
    // that never ends fails the test instead of hanging the whole run.
    final clips = await Isolate.run(_ringOfShortClips)
        .timeout(const Duration(seconds: 10));

    expect(clips, isEmpty);
  });

  test('a pool with one sound the alarm can play plays it every turn', () {
    // As in the shuffle bag: the alarm must keep ringing.
    final pool = [
      _sound('a'),
      _sound('short', duration: const Duration(milliseconds: 500)),
      _sound('rock', genre: 'rock'),
    ];

    expect(
      _ids(buildRingSequence(_alarm(genres: {'lofi'}), pool, 1)),
      List.filled(21, 'a'),
    );
  });

  group('the cap', () {
    test('is 10 min unless another one is given', () {
      // Clips of 30 s fill it exactly, so no clip runs past it.
      final pool = _pool(
        5,
        source: .user,
        duration: const Duration(seconds: 30),
      );
      final ring = buildRingSequence(_alarm(), pool, 1);
      final shortRing = buildRingSequence(
        _alarm(),
        pool,
        1,
        cap: const Duration(minutes: 2),
      );

      expect(defaultRingCap, const Duration(minutes: 10));
      expect(ring, hasLength(20));
      expect(_lengthOf(ring), const Duration(minutes: 10));
      expect(shortRing, hasLength(4));
      expect(_lengthOf(shortRing), const Duration(minutes: 2));
    });

    test('lets the last clip play whole, even past it', () {
      final ring = buildRingSequence(_alarm(), _pool(5), 1);
      final shortRing = buildRingSequence(
        _alarm(),
        _pool(5),
        1,
        cap: const Duration(seconds: 10),
      );

      expect(ring, hasLength(21));
      expect(ring.last.length, const Duration(seconds: 29));
      expect(_lengthOf(ring), const Duration(minutes: 10, seconds: 9));
      expect(shortRing, hasLength(1));
      expect(shortRing.single.length, const Duration(seconds: 29));
    });

    test('never takes more clips than it has seconds', () {
      // Every clip lasts at least a second, so the list stays short even
      // when every clip is as short as it may be.
      final pool = _pool(5, duration: const Duration(seconds: 1));

      expect(buildRingSequence(_alarm(), pool, 1), hasLength(600));
      expect(
        buildRingSequence(_alarm(), pool, 1, cap: const Duration(minutes: 1)),
        hasLength(60),
      );
    });

    test('must be positive', () {
      for (final cap in const [Duration.zero, Duration(seconds: -1)]) {
        expect(
          () => buildRingSequence(_alarm(), _pool(3), 1, cap: cap),
          throwsAssertionError,
        );
      }
    });
  });

  test('different seeds give different orders', () {
    final pool = _pool(8);
    final orders = {
      for (var seed = 0; seed < 100; seed++)
        _ids(buildRingSequence(_alarm(), pool, seed)).join(' '),
    };

    expect(orders, hasLength(greaterThan(90)));
  });

  test("gives a list that can't be changed", () {
    final clips = buildRingSequence(_alarm(), _pool(3), 1);

    expect(() => clips.add(clips.first), throwsUnsupportedError);
  });
}
