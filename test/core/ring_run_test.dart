// Separate lines keep what a test sets up apart from what it does.
// ignore_for_file: cascade_invocations

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shuffle_alarm/core/alarm.dart';
import 'package:shuffle_alarm/core/ring_run.dart';
import 'package:shuffle_alarm/core/sound.dart';
import 'package:shuffle_alarm/core/wake_up_task.dart';

Sound _sound(String name, {int seconds = 20}) => Sound(
  id: name,
  title: name,
  source: .builtin,
  genre: 'test',
  intensity: .gentle,
  duration: Duration(seconds: seconds),
);

final List<Sound> _pool = [
  for (final name in 'abcdefghi'.split('')) _sound(name),
];
final Sound _fallback = _sound('fallback');
final _alarm = Alarm(id: 'try', time: const AlarmTime(7, 0));

Duration _s(num seconds) => Duration(milliseconds: (seconds * 1000).round());

RingRun _run({
  Iterable<Sound>? pool,
  Duration cap = const Duration(minutes: 10),
  int seed = 1,
}) => RingRun(
  alarm: _alarm,
  pool: pool ?? _pool,
  fallback: _fallback,
  random: Random(seed),
  cap: cap,
);

/// Starts the next clip at [now] and returns its sound.
Sound _playNext(RingRun run, Duration now) {
  final clip = run.beginNextClip();
  run.clipStarted(now);
  return clip.sound;
}

void main() {
  group(RingRun, () {
    group('sounds', () {
      test('wants its first clip at once', () {
        final run = _run()..update(Duration.zero);

        expect(run.wantsNextClip, isTrue);
        expect(run.isOver, isFalse);
      });

      test('wants no other clip while one is on its way', () {
        final run = _run()..beginNextClip();

        run.update(_s(5));

        expect(run.wantsNextClip, isFalse);
      });

      test('plays a clip until its length runs out, by the clock', () {
        final run = _run();
        _playNext(run, _s(1));

        run.update(_s(20.9));
        expect(run.wantsNextClip, isFalse);

        run.update(_s(21));
        expect(run.wantsNextClip, isTrue);
      });

      test('never plays a clip longer than the clip rule allows', () {
        final run = _run(pool: [_sound('long', seconds: 200), _sound('b')]);
        var now = Duration.zero;
        while (run.playing?.sound.id != 'long') {
          _playNext(run, now);
        }
        now = _s(28.9);
        run.update(now);
        expect(run.wantsNextClip, isFalse);

        run.update(_s(29));
        expect(run.wantsNextClip, isTrue);
      });

      test('starts the next clip as soon as the player says one ended', () {
        final run = _run();
        _playNext(run, Duration.zero);

        run.clipEnded(_s(19.5));

        expect(run.wantsNextClip, isTrue);
      });

      test('ignores an ended clip while the next one is on its way', () {
        final run = _run();
        _playNext(run, Duration.zero);
        run.beginNextClip();

        run.clipEnded(_s(19.5));

        expect(run.wantsNextClip, isFalse);
      });

      test('says which clip is playing once it really started', () {
        final run = _run();
        final clip = run.beginNextClip();
        expect(run.playing, isNull);

        run.clipStarted(_s(2));

        expect(run.playing, clip);
      });

      test('the same seed gives the same sounds', () {
        List<String> ids(int seed) {
          final run = _run(seed: seed);
          return [
            for (var i = 0; i < 30; i++) _playNext(run, Duration.zero).id,
          ];
        }

        expect(ids(3), ids(3));
        expect(ids(3), isNot(ids(4)));
      });

      test(
        'never plays a sound twice in a row, also past the planned clips',
        () {
          for (var seed = 0; seed < 200; seed++) {
            // A short cap makes the planned clips run out often.
            final run = _run(cap: _s(30), seed: seed);
            Sound? last;
            for (var i = 0; i < 40; i++) {
              final sound = _playNext(run, Duration.zero);
              expect(sound, isNot(last), reason: 'seed $seed, clip $i');
              last = sound;
            }
          }
        },
      );

      test('keeps playing when a pool of one runs out of planned clips', () {
        final run = _run(pool: [_sound('only')], cap: _s(30));

        for (var i = 0; i < 10; i++) {
          expect(_playNext(run, Duration.zero).id, 'only');
        }
      });

      test(
        'plays the fallback when the pool is empty, so it never is silent',
        () {
          final run = _run(pool: const []);

          for (var i = 0; i < 3; i++) {
            expect(_playNext(run, Duration.zero), _fallback);
          }
        },
      );

      test('plays the fallback when every sound is too short', () {
        final blip = Sound(
          id: 'blip',
          title: 'Blip',
          source: .builtin,
          genre: 'test',
          intensity: .gentle,
          duration: const Duration(milliseconds: 500),
        );
        final run = _run(pool: [blip]);

        expect(_playNext(run, Duration.zero), _fallback);
      });

      test('plays the fallback when the alarm plays none of the genres', () {
        final run = RingRun(
          alarm: Alarm(
            id: 'try',
            time: const AlarmTime(7, 0),
            genres: const {'other'},
          ),
          pool: _pool,
          fallback: _fallback,
          random: Random(1),
        );

        expect(_playNext(run, Duration.zero), _fallback);
      });
    });

    group('a sound that fails to play', () {
      test('is followed by another try a second later', () {
        final run = _run()..beginNextClip();

        run.clipFailed(_s(2));
        expect(run.soundFailing, isTrue);
        run.update(_s(2.9));
        expect(run.wantsNextClip, isFalse);

        run.update(_s(3));
        expect(run.wantsNextClip, isTrue);
      });

      test('stops counting as failing when a sound plays', () {
        final run = _run()..beginNextClip();
        run.clipFailed(_s(2));

        _playNext(run, _s(3));

        expect(run.soundFailing, isFalse);
      });

      test('does not end the ring', () {
        final run = _run()..beginNextClip();

        run.clipFailed(_s(2));

        expect(run.isOver, isFalse);
      });
    });

    group('Stop', () {
      test('starts the given task at that moment', () {
        final run = _run();
        _playNext(run, Duration.zero);

        run.pressStop(.catchTheChange, _s(7));

        expect(run.task, isA<CatchTheChangeTask>());
        expect(run.task?.startedAt, _s(7));
        expect(run.isOver, isFalse);
      });

      for (final (kind, type) in const [
        (WakeUpTaskKind.whichSound, WhichSoundTask),
        (WakeUpTaskKind.catchTheChange, CatchTheChangeTask),
        (WakeUpTaskKind.move, MoveTask),
        (WakeUpTaskKind.litKey, LitKeyTask),
      ]) {
        test('makes a $type from ${kind.name}', () {
          final run = _run()..pressStop(kind, Duration.zero);

          expect(run.task.runtimeType, type);
        });
      }

      test('does nothing while a task runs', () {
        final run = _run()..pressStop(.move, _s(1));
        final task = run.task;

        run.pressStop(.litKey, _s(2));

        expect(run.task, same(task));
      });

      test('keeps the sounds rotating during the task', () {
        final run = _run();
        _playNext(run, Duration.zero);
        run.pressStop(.move, _s(5));

        run.update(_s(20));

        expect(run.wantsNextClip, isTrue);
      });

      test('a sound task that asks for a sound gets the next clip', () {
        final run = _run();
        _playNext(run, Duration.zero);
        run.pressStop(.whichSound, _s(5));

        run.update(_s(5));
        expect(run.wantsNextClip, isTrue);

        final clip = run.beginNextClip();
        run.clipStarted(_s(5.5));

        final task = run.task! as WhichSoundTask;
        expect(task.options, contains(clip.sound));
        expect(task.wantsNewSound, isFalse);
        expect(run.wantsNextClip, isFalse);
      });

      test('a clip that ends by itself tells the task as well', () {
        final run = _run();
        _playNext(run, Duration.zero);
        run.pressStop(.catchTheChange, _s(1));

        run.update(_s(3));
        run.clipEnded(_s(3));
        _playNext(run, _s(3.2));

        final task = run.task! as CatchTheChangeTask;
        expect(task.tap(_s(3.3)), TaskResponse.right);
      });

      test('ends the ring when the task is done', () {
        final run = _run();
        _playNext(run, Duration.zero);
        run.pressStop(.litKey, _s(1));
        final task = run.task! as LitKeyTask;

        for (var i = 0; i < LitKeyTask.pressesNeeded; i++) {
          task.press(task.litKey, _s(2));
        }
        run.update(_s(2));

        expect(run.isOver, isTrue);
        expect(run.end, RingEnd.taskDone);
        expect(run.endedAt, _s(2));
      });

      test('a timed-out task is followed by the easier fallback', () {
        final run = _run()..pressStop(.catchTheChange, _s(1));
        final deadline = run.task!.deadline;

        run.update(deadline);

        expect(run.task, isA<LitKeyTask>());
        expect(run.task?.startedAt, deadline);
        expect(run.isOver, isFalse);
      });

      test('a fallback that timed out is followed by a new one', () {
        final run = _run()..pressStop(.litKey, _s(1));
        final first = run.task!;

        run.update(first.deadline);

        expect(run.task, isA<LitKeyTask>());
        expect(run.task, isNot(same(first)));
      });
    });

    group('takeEasierTask', () {
      test('goes on with the fallback at any moment', () {
        final run = _run()..pressStop(.whichSound, _s(1));

        run.takeEasierTask(_s(2));

        expect(run.task, isA<LitKeyTask>());
        expect(run.task?.startedAt, _s(2));
      });

      test('does nothing without a task', () {
        final run = _run()..takeEasierTask(_s(2));

        expect(run.task, isNull);
      });

      test('keeps the progress of a fallback already running', () {
        final run = _run()..pressStop(.litKey, _s(1));
        final task = run.task! as LitKeyTask;
        task.press(task.litKey, _s(1));

        run.takeEasierTask(_s(2));

        expect(run.task, same(task));
      });
    });

    group('canTakeEasierTask', () {
      test('is false without a task and during the fallback', () {
        final run = _run();
        expect(run.canTakeEasierTask, isFalse);

        run.pressStop(.litKey, _s(1));
        expect(run.canTakeEasierTask, isFalse);
      });

      test('is true during any other task', () {
        final run = _run()..pressStop(.move, _s(1));

        expect(run.canTakeEasierTask, isTrue);
      });
    });

    group('showsSoundTitle', () {
      test('is true before a task and during other tasks', () {
        final run = _run();
        expect(run.showsSoundTitle, isTrue);

        run.pressStop(.catchTheChange, _s(1));
        expect(run.showsSoundTitle, isTrue);
      });

      test('is false during Which sound, which it would answer', () {
        final run = _run()..pressStop(.whichSound, _s(1));

        expect(run.showsSoundTitle, isFalse);
      });

      test('is true again after Which sound gave way to the fallback', () {
        final run = _run()..pressStop(.whichSound, _s(1));

        run.takeEasierTask(_s(2));

        expect(run.showsSoundTitle, isTrue);
      });
    });

    group('emergencyStop', () {
      test('ends the ring before any sound played', () {
        final run = _run()..emergencyStop(_s(5));

        expect(run.end, RingEnd.emergencyStop);
        expect(run.endedAt, _s(5));
      });

      test('ends the ring during a task', () {
        final run = _run()..pressStop(.move, _s(1));

        run.emergencyStop(_s(6));

        expect(run.end, RingEnd.emergencyStop);
      });
    });

    group('snooze', () {
      test('ends the ring as snoozed', () {
        final run = _run()..snooze(_s(5));

        expect(run.end, RingEnd.snoozed);
        expect(run.endedAt, _s(5));
      });

      test('does nothing during a task', () {
        final run = _run()..pressStop(.move, _s(1));

        run.snooze(_s(5));

        expect(run.isOver, isFalse);
      });
    });

    group('the cap', () {
      test('ends the ring exactly at the cap, not before', () {
        final run = _run(cap: _s(600))..update(_s(599.9));
        expect(run.isOver, isFalse);

        run.update(_s(600));

        expect(run.end, RingEnd.cap);
        expect(run.endedAt, _s(600));
      });

      test('is 10 minutes by default', () {
        final run = RingRun(
          alarm: _alarm,
          pool: _pool,
          fallback: _fallback,
          random: Random(1),
        )..update(const Duration(minutes: 10));

        expect(run.end, RingEnd.cap);
      });

      test('ends the ring during a task', () {
        final run = _run(cap: _s(600))..pressStop(.move, _s(590));

        run.update(_s(600));

        expect(run.end, RingEnd.cap);
      });

      test('ends a ring whose sounds never play', () {
        final run = _run(cap: _s(600))..beginNextClip();
        run.clipFailed(_s(1));

        run.update(_s(600));

        expect(run.end, RingEnd.cap);
      });

      test('a late update in a throttled tab still ends the ring', () {
        final run = _run(cap: _s(600))..update(_s(700));

        expect(run.end, RingEnd.cap);
      });

      test('lets a task finished before a late update count as done', () {
        final run = _run(cap: _s(600))..pressStop(.litKey, _s(590));
        final task = run.task! as LitKeyTask;
        for (var i = 0; i < LitKeyTask.pressesNeeded; i++) {
          task.press(task.litKey, _s(595));
        }

        run.update(_s(650));

        expect(run.end, RingEnd.taskDone);
      });
    });

    group('after the end', () {
      test('keeps the first way it ended', () {
        final run = _run()..emergencyStop(_s(5));

        run
          ..snooze(_s(6))
          ..update(const Duration(hours: 1))
          ..pressStop(.move, _s(7));

        expect(run.end, RingEnd.emergencyStop);
        expect(run.endedAt, _s(5));
        expect(run.task, isNull);
      });

      test('wants no more clips', () {
        final run = _run();
        _playNext(run, Duration.zero);
        run.emergencyStop(_s(1));

        run.update(_s(100));

        expect(run.wantsNextClip, isFalse);
      });

      test('a clip that started just after the end does not reopen it', () {
        final run = _run()..beginNextClip();
        run.emergencyStop(_s(1));

        run
          ..clipStarted(_s(2))
          ..clipFailed(_s(2));

        expect(run.isOver, isTrue);
        expect(run.wantsNextClip, isFalse);
      });
    });
  });

  group(WakeUpTaskPicker, () {
    const all = [
      WakeUpTaskKind.whichSound,
      WakeUpTaskKind.catchTheChange,
      WakeUpTaskKind.move,
    ];

    test('shows every possible task once before any comes back', () {
      for (var seed = 0; seed < 100; seed++) {
        final picker = WakeUpTaskPicker(Random(seed));

        final round = [for (var i = 0; i < all.length; i++) picker.next(all)];

        expect(round.toSet(), all.toSet(), reason: 'seed $seed');
      }
    });

    test('never gives the same task twice in a row across rounds', () {
      for (var seed = 0; seed < 100; seed++) {
        final picker = WakeUpTaskPicker(Random(seed));
        WakeUpTaskKind? last;
        for (var i = 0; i < 30; i++) {
          final kind = picker.next(all);
          expect(kind, isNot(last), reason: 'seed $seed, pick $i');
          last = kind;
        }
      }
    });

    test('only picks tasks that are possible now', () {
      final picker = WakeUpTaskPicker(Random(1))..next(all);

      for (var i = 0; i < 10; i++) {
        expect(picker.next(const [.litKey]), WakeUpTaskKind.litKey);
      }
    });

    test('the same seed gives the same tasks', () {
      List<WakeUpTaskKind> picks(int seed) {
        final picker = WakeUpTaskPicker(Random(seed));
        return [for (var i = 0; i < 12; i++) picker.next(all)];
      }

      expect(picks(5), picks(5));
    });
  });

  group('randomTryRingDelay', () {
    test('falls inside the next 5 minutes, with time to lie down', () {
      final random = Random(1);
      for (var i = 0; i < 10000; i++) {
        final delay = randomTryRingDelay(random);

        expect(delay, greaterThanOrEqualTo(minTryRingDelay));
        expect(delay, lessThanOrEqualTo(maxTryRingDelay));
      }
      expect(maxTryRingDelay, const Duration(minutes: 5));
    });

    test('spreads over the whole window', () {
      final random = Random(2);
      final delays = [for (var i = 0; i < 1000; i++) randomTryRingDelay(random)]
        ..sort();

      expect(delays.first, lessThan(const Duration(seconds: 40)));
      expect(delays.last, greaterThan(const Duration(seconds: 280)));
    });
  });
}
