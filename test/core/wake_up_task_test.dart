import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shuffle_alarm/core/sound.dart';
import 'package:shuffle_alarm/core/wake_up_task.dart';

Sound _sound(String title, {String? id}) => Sound(
  id: id ?? title.toLowerCase(),
  title: title,
  source: .builtin,
  genre: 'placeholder',
  intensity: .gentle,
  duration: const Duration(seconds: 23),
);

final Sound _birds = _sound('Birds');
final Sound _harp = _sound('Harp');
final Sound _drums = _sound('Drums');
final Sound _bell = _sound('Bell');
final List<Sound> _library = [_birds, _harp, _drums, _bell, _sound('Fanfare')];

/// [seconds] as a [Duration], exact to the microsecond.
Duration _s(num seconds) =>
    Duration(microseconds: (seconds * Duration.microsecondsPerSecond).round());

const _justBefore = Duration(microseconds: 1);

WhichSoundTask _whichSound({
  Iterable<Sound>? sounds,
  int seed = 1,
  Duration startedAt = Duration.zero,
}) => WhichSoundTask(
  sounds: sounds ?? _library,
  random: Random(seed),
  startedAt: startedAt,
);

CatchTheChangeTask _catchTheChange({
  int seed = 1,
  Duration startedAt = Duration.zero,
}) => CatchTheChangeTask(random: Random(seed), startedAt: startedAt);

MoveTask _move({Duration startedAt = Duration.zero}) =>
    MoveTask(random: Random(1), startedAt: startedAt);

LitKeyTask _litKey({int seed = 1, Duration startedAt = Duration.zero}) =>
    LitKeyTask(random: Random(seed), startedAt: startedAt);

/// A key of [task] that isn't lit.
int _unlitKey(LitKeyTask task) => (task.litKey + 1) % 3;

/// Moves [task] from [from] until just before [until]: [perSecond] readings
/// a second, whose strength swings between [base] and [base] + [swing].
void _shake(
  MoveTask task,
  num from,
  num until, {
  int perSecond = 20,
  double base = 9.8,
  double swing = 3,
}) {
  final readings = ((until - from) * perSecond).round();
  for (var i = 0; i < readings; i++) {
    task.reading(
      0,
      0,
      i.isEven ? base : base + swing,
      _s(from + i / perSecond),
    );
  }
}

/// How the task with [seed] ends when someone taps every [tapEvery] ticks of
/// 50 ms, whatever they hear, while the ring switches sounds when asked.
CatchTheChangeTask _mash(int seed, int tapEvery) {
  final task = _catchTheChange(seed: seed);
  for (var tick = 0; task.status == .running; tick++) {
    final now = Duration(milliseconds: 50 * tick);
    task.update(now);
    if (task.wantsNewSound) task.soundChanged(_birds, now);
    if (tick % tapEvery == 0) task.tap(now);
  }
  return task;
}

/// How long after [from] [task] asks for a new sound, checked every 50 ms.
Duration _timeUntilSwitch(CatchTheChangeTask task, Duration from) {
  var now = from;
  while (!task.wantsNewSound) {
    now += const Duration(milliseconds: 50);
    task.update(now);
  }
  return now - from;
}

void main() {
  group('every task', () {
    final tasks = <String, WakeUpTask Function(Duration startedAt)>{
      'Which sound': (startedAt) => _whichSound(startedAt: startedAt),
      'Catch the change': (startedAt) => _catchTheChange(startedAt: startedAt),
      'Move': (startedAt) => _move(startedAt: startedAt),
      'Lit key': (startedAt) => _litKey(startedAt: startedAt),
    };
    const limits = {
      'Which sound': 60,
      'Catch the change': 60,
      'Move': 90,
      'Lit key': 60,
    };

    for (final MapEntry(key: name, value: start) in tasks.entries) {
      final limit = _s(limits[name]!);

      group(name, () {
        test('runs until its time limit, counted from its start', () {
          final task = start(_s(100))..update(_s(100) + limit - _justBefore);

          expect(task.status, WakeUpTaskStatus.running);
          expect(task.deadline, _s(100) + limit);
        });

        test('times out at its time limit', () {
          final task = start(_s(100))..update(_s(100) + limit);

          expect(task.status, WakeUpTaskStatus.timedOut);
        });

        test('stays timed out', () {
          final task = start(Duration.zero)
            ..update(limit)
            ..update(limit * 2);

          expect(task.status, WakeUpTaskStatus.timedOut);
          expect(task.wantsNewSound, isFalse);
        });

        test('has as its fallback a new Lit key starting now', () {
          final fallback = start(Duration.zero).easierFallback(_s(25));

          expect(fallback.kind, WakeUpTaskKind.litKey);
          expect(fallback.startedAt, _s(25));
          expect(fallback.deadline, _s(85));
          expect(fallback.status, WakeUpTaskStatus.running);
          expect(fallback.progress, 0);
          expect(fallback.mistakes, 0);
        });

        test('has a fallback that takes no sound and no movement', () {
          final fallback = start(Duration.zero).easierFallback(Duration.zero);

          for (var i = 0; i < 5; i++) {
            expect(fallback.wantsNewSound, isFalse);
            fallback.press(fallback.litKey, _s(i));
          }

          expect(fallback.status, WakeUpTaskStatus.done);
        });
      });
    }

    test('has a new Lit key after a Lit key that timed out', () {
      final timedOut = _litKey()..update(_s(60));
      final next = timedOut.easierFallback(_s(60));

      expect(next, isNot(same(timedOut)));
      expect(next.status, WakeUpTaskStatus.running);
      expect(next.deadline, _s(120));
    });

    test('tells which kind it is', () {
      expect(_whichSound().kind, WakeUpTaskKind.whichSound);
      expect(_catchTheChange().kind, WakeUpTaskKind.catchTheChange);
      expect(_move().kind, WakeUpTaskKind.move);
      expect(_litKey().kind, WakeUpTaskKind.litKey);
    });
  });

  group(possibleWakeUpTasks, () {
    test('gives all three tasks with enough sounds and a sensor', () {
      expect(possibleWakeUpTasks(_library, hasMotionSensor: true), [
        WakeUpTaskKind.whichSound,
        WakeUpTaskKind.catchTheChange,
        WakeUpTaskKind.move,
      ]);
    });

    test('leaves out Move without a motion sensor', () {
      expect(possibleWakeUpTasks(_library, hasMotionSensor: false), [
        WakeUpTaskKind.whichSound,
        WakeUpTaskKind.catchTheChange,
      ]);
    });

    test('leaves out Which sound with fewer than 3 different titles', () {
      final twoTitles = [_birds, _harp, _sound('Harp', id: 'harp-2')];

      expect(possibleWakeUpTasks(twoTitles, hasMotionSensor: false), [
        WakeUpTaskKind.catchTheChange,
      ]);
    });

    test('leaves out both sound tasks with a single sound', () {
      expect(possibleWakeUpTasks([_birds], hasMotionSensor: true), [
        WakeUpTaskKind.move,
      ]);
    });

    test('counts sounds with the same id as one', () {
      final sameSound = [_birds, _sound('Larks', id: 'birds')];

      expect(possibleWakeUpTasks(sameSound, hasMotionSensor: false), [
        WakeUpTaskKind.litKey,
      ]);
    });

    test('falls back to Lit key when nothing else is possible', () {
      expect(possibleWakeUpTasks(const [], hasMotionSensor: false), [
        WakeUpTaskKind.litKey,
      ]);
      expect(possibleWakeUpTasks([_birds], hasMotionSensor: false), [
        WakeUpTaskKind.litKey,
      ]);
    });
  });

  group(WhichSoundTask, () {
    group('before its first sound', () {
      test('asks for a new sound and offers nothing', () {
        final task = _whichSound();

        expect(task.wantsNewSound, isTrue);
        expect(task.options, isEmpty);
      });

      test('ignores an answer', () {
        final task = _whichSound();

        expect(task.answer(_birds, _s(1)), TaskResponse.ignored);
        expect(task.mistakes, 0);
      });
    });

    group('options', () {
      test('always offer the playing sound and 2 other titles', () {
        final pool = [
          ..._library,
          _sound('Harp', id: 'harp-2'),
          _sound('Drums', id: 'drums-2'),
          _sound('Drums', id: 'drums-3'),
        ];
        for (var seed = 0; seed < 1000; seed++) {
          final task = _whichSound(sounds: pool, seed: seed)
            ..soundChanged(_harp, Duration.zero);

          final titles = {for (final sound in task.options) sound.title};
          expect(task.options, hasLength(3), reason: 'seed $seed');
          expect(titles, hasLength(3), reason: 'seed $seed');
          expect(task.options, contains(_harp), reason: 'seed $seed');
        }
      });

      test('put the playing sound on every key', () {
        final places = {
          for (var seed = 0; seed < 100; seed++)
            (_whichSound(
              seed: seed,
            )..soundChanged(_harp, Duration.zero)).options.indexOf(_harp),
        };

        expect(places, {0, 1, 2});
      });

      test('use every other title of the pool', () {
        final offered = {
          for (var seed = 0; seed < 100; seed++)
            ...(_whichSound(
              seed: seed,
            )..soundChanged(_harp, Duration.zero)).options,
        };

        expect(offered, unorderedEquals(_library));
      });

      test('include a playing sound that is not in the pool', () {
        final fallback = _sound('Fallback');
        final task = _whichSound()..soundChanged(fallback, Duration.zero);

        expect(task.options, contains(fallback));
        expect(task.options, hasLength(3));
      });

      test('are the same for the same seed, whatever the pool order', () {
        final one = _whichSound(seed: 7)..soundChanged(_harp, Duration.zero);
        final other = _whichSound(sounds: _library.reversed, seed: 7)
          ..soundChanged(_harp, Duration.zero);

        expect(other.options, one.options);
      });

      test('can not be changed', () {
        final task = _whichSound()..soundChanged(_harp, Duration.zero);

        expect(() => task.options.clear(), throwsUnsupportedError);
      });

      test('offer what there is when the pool has too few titles', () {
        final task = _whichSound(sounds: [_birds])
          ..soundChanged(_birds, Duration.zero);

        expect(task.options, [_birds]);
        expect(task.answer(_birds, _s(1)), TaskResponse.right);
      });
    });

    group('answer', () {
      late WhichSoundTask task;

      setUp(() {
        task = _whichSound()..soundChanged(_birds, Duration.zero);
      });

      test('counts the right sound and asks for a new one', () {
        expect(task.wantsNewSound, isFalse);

        expect(task.answer(_birds, _s(1)), TaskResponse.right);

        expect(task.progress, 1);
        expect(task.progressNeeded, 3);
        expect(task.mistakes, 0);
        expect(task.wantsNewSound, isTrue);
      });

      test('finishes the task after 3 right answers in a row', () {
        task
          ..answer(_birds, _s(1))
          ..soundChanged(_harp, _s(1))
          ..answer(_harp, _s(2))
          ..soundChanged(_drums, _s(2));
        expect(task.status, WakeUpTaskStatus.running);

        expect(task.answer(_drums, _s(3)), TaskResponse.right);

        expect(task.status, WakeUpTaskStatus.done);
        expect(task.progress, 3);
        expect(task.wantsNewSound, isFalse);
      });

      test('starts the count again after a wrong answer', () {
        task
          ..answer(_birds, _s(1))
          ..soundChanged(_harp, _s(1));

        expect(task.answer(_drums, _s(2)), TaskResponse.wrong);

        expect(task.progress, 0);
        expect(task.mistakes, 1);
        expect(task.wantsNewSound, isTrue);
      });

      test('needs 3 in a row, not 3 in all', () {
        final rounds = [_birds, _harp, _bell, _drums, _birds];
        for (final (i, sound) in rounds.indexed) {
          task
            ..soundChanged(sound, _s(i))
            ..answer(i == 2 ? _sound('Wrong') : sound, _s(i));
        }

        expect(task.status, WakeUpTaskStatus.running);
        expect(task.progress, 2);
      });

      test('ignores a second tap while the new sound is on its way', () {
        task.answer(_birds, _s(1));

        expect(task.answer(_birds, _s(1.1)), TaskResponse.ignored);
        expect(task.answer(_harp, _s(1.2)), TaskResponse.ignored);

        expect(task.progress, 1);
        expect(task.mistakes, 0);
      });

      test('ignores an answer after the task is done', () {
        task
          ..answer(_birds, _s(1))
          ..soundChanged(_harp, _s(1))
          ..answer(_harp, _s(2))
          ..soundChanged(_drums, _s(2))
          ..answer(_drums, _s(3));

        expect(task.answer(_harp, _s(4)), TaskResponse.ignored);

        expect(task.mistakes, 0);
        expect(task.status, WakeUpTaskStatus.done);
      });

      test('ignores an answer that comes after the time limit', () {
        expect(task.answer(_birds, _s(60)), TaskResponse.ignored);

        expect(task.status, WakeUpTaskStatus.timedOut);
        expect(task.progress, 0);
      });
    });

    group('soundChanged', () {
      test('opens a new round and keeps the count when a clip just ends', () {
        final task = _whichSound()
          ..soundChanged(_birds, Duration.zero)
          ..answer(_birds, _s(1))
          ..soundChanged(_harp, _s(1))
          ..soundChanged(_drums, _s(24));

        expect(task.progress, 1);
        expect(task.options, contains(_drums));
        expect(task.answer(_harp, _s(25)), TaskResponse.wrong);
      });

      test('opens a new round when the same sound plays again', () {
        final task = _whichSound()
          ..soundChanged(_birds, Duration.zero)
          ..answer(_birds, _s(1))
          ..soundChanged(_birds, _s(1));

        expect(task.wantsNewSound, isFalse);
        expect(task.answer(_birds, _s(2)), TaskResponse.right);
        expect(task.progress, 2);
      });

      test('does nothing after the time limit', () {
        final task = _whichSound()..soundChanged(_birds, _s(60));

        expect(task.status, WakeUpTaskStatus.timedOut);
        expect(task.options, isEmpty);
      });
    });
  });

  group(CatchTheChangeTask, () {
    group('wantsNewSound', () {
      test('is false when the task starts', () {
        expect(_catchTheChange().wantsNewSound, isFalse);
      });

      test('comes 4 to 10 s after the start, at random moments', () {
        final gaps = [
          for (var seed = 0; seed < 1000; seed++)
            _timeUntilSwitch(_catchTheChange(seed: seed), Duration.zero),
        ];

        expect(gaps.every((gap) => gap >= _s(4) && gap <= _s(10.05)), isTrue);
        expect(gaps.any((gap) => gap < _s(4.5)), isTrue);
        expect(gaps.any((gap) => gap > _s(9.5)), isTrue);
        expect(gaps.toSet().length, greaterThan(50));
      });

      test('comes 4 to 10 s after each switch, at random moments', () {
        final gaps = [
          for (var seed = 0; seed < 1000; seed++)
            _timeUntilSwitch(
              _catchTheChange(seed: seed)..soundChanged(_harp, _s(20)),
              _s(20),
            ),
        ];

        expect(gaps.every((gap) => gap >= _s(4) && gap <= _s(10.05)), isTrue);
        expect(gaps.any((gap) => gap < _s(4.5)), isTrue);
        expect(gaps.any((gap) => gap > _s(9.5)), isTrue);
      });

      test('stays on until the new sound has started', () {
        final task = _catchTheChange();
        _timeUntilSwitch(task, Duration.zero);

        task.update(_s(30));
        expect(task.wantsNewSound, isTrue);

        task.soundChanged(_harp, _s(30));
        expect(task.wantsNewSound, isFalse);
      });

      test('waits again from a clip that ended by itself', () {
        final task = _catchTheChange()
          ..soundChanged(_harp, _s(3.9))
          ..update(_s(3.9 + 4) - _justBefore);

        expect(task.wantsNewSound, isFalse);
      });

      test('is the same for the same seed', () {
        expect(
          _timeUntilSwitch(_catchTheChange(seed: 3), Duration.zero),
          _timeUntilSwitch(_catchTheChange(seed: 3), Duration.zero),
        );
      });

      test('counts the first gap from the start of the task', () {
        final task = _catchTheChange(startedAt: _s(100))
          ..update(_s(104) - _justBefore);

        expect(task.wantsNewSound, isFalse);
      });

      test('is false after the task has ended', () {
        final task = _catchTheChange()..update(_s(60));

        expect(task.wantsNewSound, isFalse);
      });

      test('stays false when a sound starts after the time limit', () {
        final task = _catchTheChange()..soundChanged(_harp, _s(60));

        expect(task.status, WakeUpTaskStatus.timedOut);
        expect(task.tap(_s(60)), TaskResponse.ignored);
      });
    });

    group('tap', () {
      late CatchTheChangeTask task;

      setUp(() {
        task = _catchTheChange()..soundChanged(_harp, _s(5));
      });

      test('catches a switch at the moment it happens', () {
        expect(task.tap(_s(5)), TaskResponse.right);
        expect(task.progress, 1);
        expect(task.progressNeeded, 3);
      });

      test('catches a switch at exactly 1.5 s', () {
        expect(task.tap(_s(6.5)), TaskResponse.right);
        expect(task.progress, 1);
      });

      test('is wrong just after 1.5 s', () {
        expect(task.tap(_s(6.5) + _justBefore), TaskResponse.wrong);
        expect(task.progress, 0);
        expect(task.mistakes, 1);
      });

      test('is wrong before any switch', () {
        final fresh = _catchTheChange();

        expect(fresh.tap(_s(1)), TaskResponse.wrong);
        expect(fresh.progress, 0);
        expect(fresh.mistakes, 1);
      });

      test('finishes the task after catching 3 switches', () {
        task
          ..tap(_s(6))
          ..soundChanged(_drums, _s(12))
          ..tap(_s(13))
          ..soundChanged(_bell, _s(20));
        expect(task.status, WakeUpTaskStatus.running);

        expect(task.tap(_s(21)), TaskResponse.right);

        expect(task.status, WakeUpTaskStatus.done);
        expect(task.progress, 3);
        expect(task.mistakes, 0);
      });

      test('takes back one catch when it misses', () {
        task
          ..tap(_s(6))
          ..soundChanged(_drums, _s(12))
          ..tap(_s(13));

        expect(task.tap(_s(16)), TaskResponse.wrong);

        expect(task.progress, 1);
        expect(task.mistakes, 1);
      });

      test('ignores a second tap on the same switch', () {
        task.tap(_s(5.5));

        expect(task.tap(_s(5.7)), TaskResponse.ignored);

        expect(task.progress, 1);
        expect(task.mistakes, 0);
      });

      test('is wrong again after the window of a caught switch', () {
        task.tap(_s(5.5));

        expect(task.tap(_s(6.6)), TaskResponse.wrong);

        expect(task.progress, 0);
      });

      test('does not count a missed switch as a mistake', () {
        task.soundChanged(_drums, _s(12));

        expect(task.mistakes, 0);
        expect(task.progress, 0);
      });

      test('ignores a tap that comes after the time limit', () {
        expect(task.tap(_s(60)), TaskResponse.ignored);

        expect(task.status, WakeUpTaskStatus.timedOut);
        expect(task.mistakes, 0);
      });

      test('ignores a tap after the task is done', () {
        task
          ..tap(_s(6))
          ..soundChanged(_drums, _s(12))
          ..tap(_s(13))
          ..soundChanged(_bell, _s(20))
          ..tap(_s(21));

        expect(task.tap(_s(40)), TaskResponse.ignored);

        expect(task.progress, 3);
        expect(task.mistakes, 0);
      });
    });

    group('in 1000 random tasks', () {
      for (final (tapEvery, label) in [
        (5, '0.25 s'),
        (10, '0.5 s'),
        (20, '1 s'),
        (40, '2 s'),
      ]) {
        test('tapping blindly every $label never finishes', () {
          final finished = [
            for (var seed = 0; seed < 1000; seed++)
              if (_mash(seed, tapEvery).status != .timedOut) seed,
          ];

          expect(finished, isEmpty);
        });
      }

      test('someone who taps soon after each switch finishes in time', () {
        final unfinished = <int>[];
        for (var seed = 0; seed < 1000; seed++) {
          final task = _catchTheChange(seed: seed);
          for (var tick = 0; task.status == .running; tick++) {
            final now = Duration(milliseconds: 50 * tick);
            task.update(now);
            if (task.wantsNewSound) {
              task
                ..soundChanged(_harp, now)
                ..tap(now + const Duration(milliseconds: 800));
            }
          }
          if (task.status != .done) unfinished.add(seed);
        }

        expect(unfinished, isEmpty);
      });
    });
  });

  group(MoveTask, () {
    group('reading', () {
      test('counts 30 s of movement, not before', () {
        final task = _move();
        _shake(task, 0, 30);

        expect(task.status, WakeUpTaskStatus.running);
        expect(task.progress, 29);
        expect(task.progressNeeded, 30);

        task.update(_s(30));

        expect(task.status, WakeUpTaskStatus.done);
        expect(task.progress, 30);
      });

      for (final perSecond in [5, 20, 60]) {
        test('counts the same with $perSecond readings a second', () {
          final task = _move();
          _shake(task, 0, 30, perSecond: perSecond);
          task.update(_s(30));

          expect(task.status, WakeUpTaskStatus.done);
        });
      }

      test('counts from the start of the task, not from the ring', () {
        final task = _move(startedAt: _s(0.5));
        _shake(task, 0.5, 30.5);
        task.update(_s(30.5) - _justBefore);
        expect(task.status, WakeUpTaskStatus.running);

        task.update(_s(30.5));

        expect(task.status, WakeUpTaskStatus.done);
      });

      test('keeps the movement from before a pause', () {
        final task = _move();
        _shake(task, 0, 10);
        task.update(_s(30));
        expect(task.progress, 10);

        _shake(task, 30, 50);
        task.update(_s(50));

        expect(task.status, WakeUpTaskStatus.done);
      });

      test('does not count a phone lying still', () {
        final task = _move();
        _shake(task, 0, 60, swing: 0.05);
        task.update(_s(60));

        expect(task.progress, 0);
      });

      test('does not count a swing just under the threshold', () {
        final task = _move();
        _shake(task, 0, 5, base: 10, swing: 1.99);
        task.update(_s(5));

        expect(task.progress, 0);
      });

      test('counts a swing at the threshold', () {
        final task = _move();
        _shake(task, 0, 5, base: 10, swing: 2);
        task.update(_s(5));

        expect(task.progress, 5);
      });

      test('counts a sensor that takes gravity out', () {
        final task = _move();
        _shake(task, 0, 5, base: 0);
        task.update(_s(5));

        expect(task.progress, 5);
      });

      test('uses all three axes', () {
        final task = _move();
        for (var i = 0; i < 100; i++) {
          final strength = i.isEven ? 6.0 : 9.0;
          task.reading(strength, strength, 0, _s(i / 20));
        }
        task.update(_s(5));

        expect(task.progress, 5);
      });

      test('does not count a phone turned slowly', () {
        final task = _move();
        for (var i = 0; i < 200; i++) {
          final angle = i * pi / 100;
          task.reading(9.8 * cos(angle), 9.8 * sin(angle), 0, _s(i / 20));
        }
        task.update(_s(10));

        expect(task.progress, 0);
      });

      test('counts one second at most for a strong jolt', () {
        final task = _move()
          ..reading(0, 0, 10, _s(0.1))
          ..reading(0, 0, 80, _s(0.2))
          ..update(_s(30));

        expect(task.progress, 1);
      });

      test('does not compare readings of different seconds', () {
        final task = _move()
          ..reading(0, 0, 10, _s(1.5))
          ..reading(0, 0, 80, _s(40.2))
          ..update(_s(50));

        expect(task.progress, 0);
      });

      test('starts each second afresh', () {
        final task = _move()
          ..reading(0, 0, 10, _s(0.1))
          ..reading(0, 0, 13, _s(0.2))
          ..reading(0, 0, 20, _s(1.1))
          ..reading(0, 0, 20.1, _s(1.2))
          ..reading(0, 0, 10, _s(2.1))
          ..reading(0, 0, 10.1, _s(2.2))
          ..update(_s(3));

        expect(task.progress, 1);
      });

      test('skips readings that are not numbers', () {
        final task = _move()
          ..reading(0, 0, 10, _s(0.1))
          ..reading(double.nan, 0, 0, _s(0.2))
          ..reading(double.infinity, 0, 0, _s(0.3))
          ..reading(0, 0, 10.5, _s(0.4))
          ..update(_s(1));
        expect(task.progress, 0);

        task
          ..reading(0, 0, 10, _s(1.1))
          ..reading(double.nan, 0, 0, _s(1.2))
          ..reading(0, 0, 13, _s(1.3))
          ..update(_s(2));
        expect(task.progress, 1);
      });

      test('ignores readings after the time limit', () {
        final task = _move();
        _shake(task, 61, 90);
        task.reading(0, 0, 10, _s(91));

        expect(task.status, WakeUpTaskStatus.timedOut);
        expect(task.progress, 29);
      });

      test('counts a second that ended right at the time limit', () {
        final task = _move();
        _shake(task, 60, 90);
        task.update(_s(90));

        expect(task.status, WakeUpTaskStatus.done);
      });

      test('counts seconds even when the tick comes late', () {
        final task = _move();
        _shake(task, 60, 90);
        task.update(_s(95));

        expect(task.status, WakeUpTaskStatus.done);
      });
    });

    test('never asks for a new sound', () {
      final task = _move()..update(_s(20));

      expect(task.wantsNewSound, isFalse);
    });
  });

  group(LitKeyTask, () {
    test('lights every key across tasks', () {
      final lit = {
        for (var seed = 0; seed < 100; seed++) _litKey(seed: seed).litKey,
      };

      expect(lit, {0, 1, 2});
    });

    test('never lights the same key twice in a row', () {
      for (var seed = 0; seed < 1000; seed++) {
        final task = _litKey(seed: seed);
        for (var i = 0; i < 4; i++) {
          final before = task.litKey;
          task.press(before, _s(i));
          expect(task.litKey, isNot(before), reason: 'seed $seed, press $i');
          expect(task.litKey, inInclusiveRange(0, 2));
        }
      }
    });

    test('moves the light to both other keys across tasks', () {
      final next = {
        for (var seed = 0; seed < 100; seed++)
          () {
            final task = _litKey(seed: seed);
            final first = task.litKey;
            task.press(first, Duration.zero);
            return (first, task.litKey);
          }(),
      };

      expect(next, hasLength(6));
    });

    test('is the same for the same seed', () {
      expect(_litKey(seed: 5).litKey, _litKey(seed: 5).litKey);
    });

    group('press', () {
      late LitKeyTask task;

      setUp(() {
        task = _litKey();
      });

      test('counts the lit key', () {
        expect(task.press(task.litKey, _s(1)), TaskResponse.right);

        expect(task.progress, 1);
        expect(task.progressNeeded, 5);
        expect(task.mistakes, 0);
      });

      test('finishes the task after 5 presses, not before', () {
        for (var i = 0; i < 4; i++) {
          task.press(task.litKey, _s(i));
        }
        expect(task.status, WakeUpTaskStatus.running);

        task.press(task.litKey, _s(4));

        expect(task.status, WakeUpTaskStatus.done);
        expect(task.progress, 5);
      });

      test('counts a wrong key as a mistake and keeps the count', () {
        task.press(task.litKey, _s(1));
        final lit = task.litKey;

        expect(task.press(_unlitKey(task), _s(2)), TaskResponse.wrong);

        expect(task.progress, 1);
        expect(task.mistakes, 1);
        expect(task.litKey, lit);
      });

      test('counts a key that does not exist as a mistake', () {
        expect(task.press(3, _s(1)), TaskResponse.wrong);
        expect(task.press(-1, _s(1)), TaskResponse.wrong);

        expect(task.mistakes, 2);
      });

      test('ignores a press after the task is done', () {
        for (var i = 0; i < 5; i++) {
          task.press(task.litKey, _s(i));
        }

        expect(task.press(_unlitKey(task), _s(6)), TaskResponse.ignored);

        expect(task.mistakes, 0);
        expect(task.progress, 5);
      });

      test('ignores a press that comes after the time limit', () {
        expect(task.press(task.litKey, _s(60)), TaskResponse.ignored);

        expect(task.status, WakeUpTaskStatus.timedOut);
        expect(task.progress, 0);
      });
    });
  });

  group('a task that is done', () {
    test('stays done after its time limit', () {
      final task = _litKey();
      for (var i = 0; i < 5; i++) {
        task.press(task.litKey, _s(i));
      }

      task.update(_s(200));

      expect(task.status, WakeUpTaskStatus.done);
    });
  });
}
