import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shuffle_alarm/core/shuffle_bag.dart';
import 'package:shuffle_alarm/core/sound.dart';

Sound _sound(String id, {String title = 'Slow Sunrise'}) => Sound(
  id: id,
  title: title,
  source: .builtin,
  genre: 'lofi',
  intensity: .gentle,
  duration: const Duration(seconds: 29),
);

/// [count] sounds with the ids `sound-00`, `sound-01` and so on.
List<Sound> _pool(int count) => [
  for (var i = 0; i < count; i++)
    _sound('sound-${i.toString().padLeft(2, '0')}'),
];

/// The ids of the next [count] sounds from [bag].
List<String> _draw(ShuffleBag bag, int count) => [
  for (var i = 0; i < count; i++) bag.next()!.id,
];

/// The ids of a bag's pool and of the sounds it gave with its seed.
typedef _Run = ({int seed, List<String> pool, List<String> ids});

/// The first 5 rounds of 1000 bags of 2 to 30 sounds, each bag with its own
/// seed, so every bag refills 4 times. The seeds are fixed, so every run
/// checks the same sequences.
List<_Run> _randomRuns() => [
  for (var seed = 0; seed < 1000; seed++) _run(seed, _pool(2 + seed % 29)),
];

_Run _run(int seed, List<Sound> pool) => (
  seed: seed,
  pool: [for (final sound in pool) sound.id],
  ids: _draw(ShuffleBag(pool, Random(seed)), 5 * pool.length),
);

void main() {
  group('in the first 5 rounds of 1000 random bags', () {
    test('every sound plays once per round', () {
      expect([
        for (final (:seed, :pool, :ids) in _randomRuns())
          for (final (i, round) in ids.slices(pool.length).indexed)
            if (!const UnorderedIterableEquality<String>().equals(round, pool))
              'seed $seed, round ${i + 1}: $round',
      ], isEmpty);
    });

    test('no sound plays twice in a row, also when the bag refills', () {
      expect([
        for (final (:seed, pool: _, :ids) in _randomRuns())
          for (var i = 1; i < ids.length; i++)
            if (ids[i] == ids[i - 1]) 'seed $seed, turn ${i + 1}: ${ids[i]}',
      ], isEmpty);
    });
  });

  test('every sound has the same chance to play first', () {
    // 4 sounds and 1000 seeds: each sound should come first about 250 times.
    final pool = _pool(4);
    final counts = <String, int>{};
    for (var seed = 0; seed < 1000; seed++) {
      final id = ShuffleBag(pool, Random(seed)).next()!.id;
      counts.update(id, (count) => count + 1, ifAbsent: () => 1);
    }

    expect(counts.keys, unorderedEquals(pool.map((sound) => sound.id)));
    expect(counts.values, everyElement(inInclusiveRange(200, 300)));
  });

  test('an empty pool gives no sound', () {
    final bag = ShuffleBag(const [], Random(1));

    for (var i = 0; i < 3; i++) {
      expect(bag.next(), isNull);
    }
  });

  test('a pool of one sound plays it every turn', () {
    // Twice in a row can't be avoided here, and the alarm must still ring.
    final sound = _sound('a');

    for (final pool in [
      [sound],
      [sound, sound],
    ]) {
      final bag = ShuffleBag(pool, Random(1));
      expect([for (var i = 0; i < 5; i++) bag.next()], List.filled(5, sound));
    }
  });

  test('a pool of two sounds takes turns, starting with either one', () {
    final (a, b) = (_sound('a'), _sound('b'));
    final firsts = <Sound>{};

    for (var seed = 0; seed < 100; seed++) {
      final bag = ShuffleBag([a, b], Random(seed));
      final first = bag.next()!;
      final second = first == a ? b : a;
      firsts.add(first);
      expect(
        [for (var turn = 2; turn <= 10; turn++) bag.next()],
        [
          for (var turn = 2; turn <= 10; turn++)
            if (turn.isEven) second else first,
        ],
      );
    }
    expect(firsts, {a, b});
  });

  group('a sound that is in the pool twice', () {
    test('plays once per round', () {
      final (a, b, c) = (_sound('a'), _sound('b'), _sound('c'));

      for (var seed = 0; seed < 100; seed++) {
        final ids = _draw(ShuffleBag([a, b, a, c, a], Random(seed)), 9);
        for (final round in ids.slices(3)) {
          expect(round, unorderedEquals(['a', 'b', 'c']));
        }
      }
    });

    test('counts as one sound when only its id is the same', () {
      // The id names a sound in ring events and weights; the first one wins.
      final first = _sound('a');
      final copy = _sound('a', title: 'Bright Sunrise');
      final b = _sound('b');

      for (var seed = 0; seed < 100; seed++) {
        final bag = ShuffleBag([first, b, copy], Random(seed));
        final sounds = [for (var i = 0; i < 6; i++) bag.next()];
        expect(sounds.toSet(), {first, b});
      }
    });
  });

  group('the same seed', () {
    test('gives the same sequence', () {
      final pool = _pool(8);

      for (var seed = 0; seed < 100; seed++) {
        expect(
          _draw(ShuffleBag(pool, Random(seed)), 40),
          _draw(ShuffleBag(pool, Random(seed)), 40),
        );
      }
    });

    test('gives the same sequence whatever the order of the pool', () {
      final pool = _pool(8);
      final reordered = [
        pool.reversed,
        [...pool.skip(3), ...pool.take(3)],
      ];

      for (var seed = 0; seed < 100; seed++) {
        final sequence = _draw(ShuffleBag(pool, Random(seed)), 40);
        for (final other in reordered) {
          expect(_draw(ShuffleBag(other, Random(seed)), 40), sequence);
        }
      }
    });
  });
}
