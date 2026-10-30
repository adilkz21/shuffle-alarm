import 'dart:async';
import 'dart:math';

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/app.dart';
import 'package:shuffle_alarm/core/ring_run.dart';
import 'package:shuffle_alarm/core/wake_up_task.dart';
import 'package:shuffle_alarm/data/sound_library.dart';
import 'package:shuffle_alarm/features/ringing/hold_to_stop_key.dart';
import 'package:shuffle_alarm/features/ringing/ringing_screen.dart';
import 'package:shuffle_alarm/features/ringing/try_ring.dart';
import 'package:shuffle_alarm/platform/motion_sensor.dart';
import 'package:shuffle_alarm/platform/screen_awake.dart';
import 'package:shuffle_alarm/platform/sound_player.dart';

/// A library of [names], one sound each, 20 s long.
SoundLibrary _library(List<String> names) => SoundLibrary.fromManifest('''
{"sounds": [${names.map((name) => '''
  {"id": "$name", "title": "$name", "artist": "Us", "genre": "test",
   "intensity": 1, "file": "test/$name.wav", "durationSec": 20,
   "license": "original", "sourceUrl": "", "attribution": ""}
''').join(',')}]}''');

final class _FakePlayer implements SoundPlayer {
  final played = <String>[];
  final ended = StreamController<void>.broadcast();
  int unlocks = 0;
  int stops = 0;
  List<String> preloaded = <String>[];
  bool fails = false;

  /// While set, sounds wait for it before they start.
  Completer<void>? gate;

  @override
  Future<void> unlock() async => unlocks++;

  @override
  Future<void> preload(Iterable<String> assets) async =>
      preloaded = assets.toList();

  @override
  Future<void> play(String asset, {Duration start = Duration.zero}) async {
    await gate?.future;
    if (fails) throw StateError('blocked');
    played.add(asset);
  }

  @override
  Future<void> stop() async => stops++;

  @override
  Stream<void> get onEnded => ended.stream;

  @override
  Future<void> dispose() => ended.close();
}

final class _FakeMotion implements MotionSensor {
  new({this.available = false, this.needsPermission = false});

  final bool available;
  final readingsController = StreamController<MotionReading>.broadcast();
  bool permissionAsked = false;

  @override
  bool needsPermission;

  @override
  Future<bool> requestPermission() async {
    permissionAsked = true;
    needsPermission = false;
    return true;
  }

  @override
  Future<bool> isAvailable() async => available;

  @override
  Stream<MotionReading> get readings => readingsController.stream;
}

final class _FakeScreen implements ScreenAwake {
  bool kept = false;

  @override
  Future<void> keepOn() async => kept = true;

  @override
  Future<void> allowOff() async => kept = false;
}

/// Shared by every stopwatch of a test, which [_Rig.pass] moves on.
final class _FakeTime {
  Duration now = Duration.zero;
}

final class _FakeStopwatch extends Fake implements Stopwatch {
  new(this._time) : _startedAt = _time.now;

  final _FakeTime _time;
  final Duration _startedAt;

  @override
  void start() {}

  @override
  Duration get elapsed => _time.now - _startedAt;
}

final class _Rig {
  new(this.tester, {_FakeMotion? motion, List<String>? sounds})
    : motion = motion ?? _FakeMotion(),
      library = _library(sounds ?? 'abcdefghi'.split(''));

  final WidgetTester tester;
  final _FakeMotion motion;
  final SoundLibrary library;
  final player = _FakePlayer();
  final screen = _FakeScreen();
  final time = _FakeTime();

  late final ProviderContainer container = ProviderContainer.test(
    overrides: [
      soundPlayerProvider.overrideWithValue(player),
      motionSensorProvider.overrideWithValue(motion),
      screenAwakeProvider.overrideWithValue(screen),
      soundLibraryProvider.overrideWith((ref) async => library),
      ringStopwatchProvider.overrideWithValue(() => _FakeStopwatch(time)),
      ringRandomProvider.overrideWithValue(Random(1)),
    ],
  );

  TryRingState get state => container.read(tryRingProvider);

  RingRun get run => state.run!;

  Future<void> start() async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ShuffleAlarmApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Moves the clock on and lets the ticks see it.
  Future<void> pass(Duration time) async {
    this.time.now += time;
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
  }

  Future<void> tapText(String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pump();
    await tester.pump();
  }

  Future<void> ringNow() async {
    await tapText('Try a ring');
    await tapText('Ring now');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    await tester.pump();
  }

  /// Ends the ring, so the test leaves no timers behind.
  Future<void> finish() async {
    if (state.phase == .ringing) {
      container.read(tryRingProvider.notifier).emergencyStop();
    }
    if (state.phase == .waiting) {
      container.read(tryRingProvider.notifier).cancelWaiting();
    }
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }
}

void main() {
  group('Try a ring', () {
    testWidgets('asks when, then Ring now opens the ringing screen', (
      tester,
    ) async {
      final rig = _Rig(tester);
      await rig.start();

      await rig.tapText('Try a ring');
      expect(find.text('Within 5 minutes'), findsOneWidget);

      await rig.tapText('Ring now');
      await tester.pumpAndSettleSoon();

      expect(find.byType(RingingScreen), findsOneWidget);
      expect(rig.player.played, isNotEmpty);
      expect(rig.player.unlocks, 1);
      expect(rig.screen.kept, isTrue);
      await rig.finish();
    });

    testWidgets('gets all the sounds ready up front', (tester) async {
      final rig = _Rig(tester);
      await rig.start();

      await rig.ringNow();

      expect(rig.player.preloaded, hasLength(9));
      await rig.finish();
    });

    testWidgets('within 5 minutes waits, with no sign of when', (tester) async {
      final rig = _Rig(tester);
      await rig.start();

      await rig.tapText('Try a ring');
      await rig.tapText('Within 5 minutes');
      await rig.pass(const Duration(seconds: 1));

      expect(rig.state.phase, TryRingPhase.waiting);
      expect(find.text('--:--'), findsOneWidget);
      expect(find.byType(RingingScreen), findsNothing);
      expect(rig.player.played, isEmpty);
      expect(rig.screen.kept, isTrue);

      await rig.pass(const Duration(minutes: 5));
      await tester.pumpAndSettleSoon();

      expect(find.byType(RingingScreen), findsOneWidget);
      expect(rig.player.played, isNotEmpty);
      await rig.finish();
    });

    testWidgets('Cancel calls off a ring on its way', (tester) async {
      final rig = _Rig(tester);
      await rig.start();
      await rig.tapText('Try a ring');
      await rig.tapText('Within 5 minutes');
      await rig.pass(const Duration(seconds: 1));

      await rig.tapText('Cancel');
      await rig.pass(const Duration(minutes: 6));

      expect(rig.state.phase, TryRingPhase.idle);
      expect(rig.player.played, isEmpty);
      expect(rig.screen.kept, isFalse);
      await rig.finish();
    });

    testWidgets('where the browser asks first, explains before asking', (
      tester,
    ) async {
      final rig = _Rig(tester, motion: _FakeMotion(needsPermission: true));
      await rig.start();

      await rig.tapText('Try a ring');
      await rig.tapText('Ring now');
      expect(find.text('One task uses motion'), findsOneWidget);
      expect(rig.motion.permissionAsked, isFalse);
      expect(rig.state.phase, TryRingPhase.idle);

      await rig.tapText('Continue');
      await tester.pumpAndSettleSoon();

      expect(rig.motion.permissionAsked, isTrue);
      expect(rig.state.phase, TryRingPhase.ringing);
      await rig.finish();
    });

    testWidgets('the explanation can be skipped, and the ring still comes', (
      tester,
    ) async {
      final rig = _Rig(tester, motion: _FakeMotion(needsPermission: true));
      await rig.start();

      await rig.tapText('Try a ring');
      await rig.tapText('Ring now');
      await rig.tapText('Skip the Move task');
      await tester.pumpAndSettleSoon();

      expect(rig.motion.permissionAsked, isFalse);
      expect(rig.state.phase, TryRingPhase.ringing);
      await rig.finish();
    });
  });

  group('the ringing screen', () {
    testWidgets('shows a clock, the sound, Stop and Snooze', (tester) async {
      final rig = _Rig(tester);
      await rig.start();
      await rig.ringNow();

      expect(find.text(rig.run.playing!.sound.title), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);
      expect(find.text('Snooze'), findsOneWidget);
      await rig.finish();
    });

    testWidgets('moves to a new sound when the clip ends, by the clock', (
      tester,
    ) async {
      final rig = _Rig(tester);
      await rig.start();
      await rig.ringNow();
      final first = rig.run.playing;

      await rig.pass(const Duration(seconds: 20));

      expect(rig.player.played, hasLength(2));
      expect(rig.run.playing, isNot(first));
      await rig.finish();
    });

    testWidgets('moves to a new sound as soon as the player says it ended', (
      tester,
    ) async {
      final rig = _Rig(tester);
      await rig.start();
      await rig.ringNow();

      rig.player.ended.add(null);
      await tester.pump();
      await tester.pump();

      expect(rig.player.played, hasLength(2));
      await rig.finish();
    });

    testWidgets('never plays the same sound twice in a row', (tester) async {
      final rig = _Rig(tester);
      await rig.start();
      await rig.ringNow();

      for (var i = 0; i < 25; i++) {
        await rig.pass(const Duration(seconds: 20));
      }

      expect(rig.player.played.length, greaterThan(20));
      for (var i = 1; i < rig.player.played.length; i++) {
        expect(rig.player.played[i], isNot(rig.player.played[i - 1]));
      }
      await rig.finish();
    });

    testWidgets('plays the fallback when the library is empty', (tester) async {
      final rig = _Rig(tester, sounds: []);
      await rig.start();
      await rig.ringNow();

      expect(rig.player.played.single, contains('alarm-clock'));
      await rig.finish();
    });

    testWidgets('says so when the sound fails, and keeps ringing', (
      tester,
    ) async {
      final rig = _Rig(tester);
      await rig.start();
      rig.player.fails = true;
      await rig.ringNow();

      expect(find.text('The sound can’t play.'), findsOneWidget);

      await rig.tapText('Turn the sound on');
      rig.player.fails = false;
      await rig.pass(const Duration(seconds: 1));

      expect(rig.player.played, hasLength(1));
      expect(find.text('The sound can’t play.'), findsNothing);
      await rig.finish();
    });

    testWidgets('fits a narrow screen with Snooze on one line', (tester) async {
      tester.view.physicalSize = const Size(280, 560);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final rig = _Rig(tester);
      await rig.start();
      await rig.ringNow();

      expect(tester.takeException(), isNull);
      final lineHeight = tester.getSize(find.text('Stop')).height;
      expect(tester.getSize(find.text('Snooze')).height, lineHeight);
      await rig.finish();
    });

    testWidgets('the back button does not leave a ring', (tester) async {
      final rig = _Rig(tester);
      await rig.start();
      await rig.ringNow();

      await tester.binding.handlePopRoute();
      await tester.pump();

      expect(find.byType(RingingScreen), findsOneWidget);
      await rig.finish();
    });
  });

  group('Stop', () {
    testWidgets('opens a task and hides Snooze while sounds go on', (
      tester,
    ) async {
      final rig = _Rig(tester);
      await rig.start();
      await rig.ringNow();
      final played = rig.player.played.length;

      await rig.tapText('Stop');
      await tester.pump();

      expect(rig.run.task, isNotNull);
      expect(find.text('Snooze'), findsNothing);

      await rig.pass(const Duration(seconds: 20));
      expect(rig.player.played.length, greaterThan(played));
      expect(rig.state.phase, TryRingPhase.ringing);
      await rig.finish();
    });

    testWidgets('never offers Move without a motion sensor', (tester) async {
      final rig = _Rig(tester);
      await rig.start();
      final seen = <WakeUpTaskKind>{};
      for (var i = 0; i < 6; i++) {
        await rig.ringNow();
        await rig.tapText('Stop');
        seen.add(rig.run.task!.kind);
        rig.container.read(tryRingProvider.notifier).emergencyStop();
        await tester.pumpAndSettleSoon();
        if (i < 5) {
          await tester.pumpAndSettleSoon();
        }
      }

      expect(seen, {WakeUpTaskKind.whichSound, WakeUpTaskKind.catchTheChange});
      await rig.finish();
    });

    testWidgets('offers Move with a motion sensor, and readings count', (
      tester,
    ) async {
      final rig = _Rig(tester, motion: _FakeMotion(available: true));
      await rig.start();
      final notifier = rig.container.read(tryRingProvider.notifier);
      var triesLeft = 6;
      while (triesLeft-- > 0) {
        await rig.ringNow();
        await rig.tapText('Stop');
        if (rig.run.task is MoveTask) break;
        notifier.emergencyStop();
        await tester.pumpAndSettleSoon();
      }
      expect(rig.run.task, isA<MoveTask>());

      for (var second = 0; second < 30; second++) {
        rig.motion.readingsController
          ..add((x: 0, y: 0, z: 9))
          ..add((x: 0, y: 0, z: 13));
        await tester.pump();
        await rig.pass(const Duration(seconds: 1));
      }
      await tester.pumpAndSettleSoon();

      expect(rig.state.lastEnd, RingEnd.taskDone);
      await rig.finish();
    });

    testWidgets('Which sound hides the title and three right answers end it', (
      tester,
    ) async {
      final rig = _Rig(tester);
      await rig.start();
      final notifier = rig.container.read(tryRingProvider.notifier);
      var triesLeft = 6;
      while (triesLeft-- > 0) {
        await rig.ringNow();
        await rig.tapText('Stop');
        await tester.pump();
        await tester.pump();
        if (rig.run.task is WhichSoundTask) break;
        notifier.emergencyStop();
        await tester.pumpAndSettleSoon();
      }
      expect(rig.run.task, isA<WhichSoundTask>());
      expect(find.text('Sound hidden'), findsOneWidget);

      for (var i = 0; i < WhichSoundTask.answersNeeded; i++) {
        final title = rig.run.playing!.sound.title;
        // The title shows only on its key.
        expect(find.text(title), findsOneWidget);
        await rig.tapText(title);
        await tester.pump();
        await tester.pump();
        await tester.pump();
      }
      await tester.pumpAndSettleSoon();

      expect(rig.state.lastEnd, RingEnd.taskDone);
      expect(rig.player.stops, greaterThan(0));
      expect(find.byType(RingingScreen), findsNothing);
      expect(find.text('LAST TRY: TASK DONE'), findsOneWidget);
      expect(rig.screen.kept, isFalse);
      await rig.finish();
    });

    testWidgets('Catch the change finishes with three caught switches', (
      tester,
    ) async {
      final rig = _Rig(tester);
      await rig.start();
      final notifier = rig.container.read(tryRingProvider.notifier);
      var triesLeft = 6;
      while (triesLeft-- > 0) {
        await rig.ringNow();
        await rig.tapText('Stop');
        if (rig.run.task is CatchTheChangeTask) break;
        notifier.emergencyStop();
        await tester.pumpAndSettleSoon();
      }
      expect(rig.run.task, isA<CatchTheChangeTask>());

      for (var i = 0; i < CatchTheChangeTask.catchesNeeded; i++) {
        final played = rig.player.played.length;
        while (rig.player.played.length == played) {
          await rig.pass(const Duration(seconds: 1));
        }
        await rig.tapText('It changed!');
      }
      await tester.pumpAndSettleSoon();

      expect(rig.state.lastEnd, RingEnd.taskDone);
      await rig.finish();
    });

    testWidgets('Which sound keeps its keys in place while a sound loads', (
      tester,
    ) async {
      final rig = _Rig(tester);
      await rig.start();
      final notifier = rig.container.read(tryRingProvider.notifier);
      var triesLeft = 6;
      while (triesLeft-- > 0) {
        await rig.ringNow();
        rig.player.gate = Completer();
        await rig.tapText('Stop');
        await tester.pump();
        if (rig.run.task is WhichSoundTask) break;
        rig.player.gate!.complete();
        rig.player.gate = null;
        notifier.emergencyStop();
        await tester.pumpAndSettleSoon();
      }
      expect(rig.run.task, isA<WhichSoundTask>());

      expect(find.text('…'), findsNWidgets(WhichSoundTask.optionCount));
      final linkTop = tester.getTopLeft(find.text('Try an easier task')).dy;

      rig.player.gate!.complete();
      rig.player.gate = null;
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('…'), findsNothing);
      expect(tester.getTopLeft(find.text('Try an easier task')).dy, linkTop);
      await rig.finish();
    });

    testWidgets('Try an easier task leads to Lit key, which ends the ring', (
      tester,
    ) async {
      final rig = _Rig(tester);
      await rig.start();
      await rig.ringNow();
      await rig.tapText('Stop');

      await rig.tapText('Try an easier task');
      expect(rig.run.task, isA<LitKeyTask>());
      expect(find.text('Try an easier task'), findsNothing);

      for (var i = 0; i < LitKeyTask.pressesNeeded; i++) {
        await rig.tapText('LIT');
      }
      await tester.pumpAndSettleSoon();

      expect(rig.state.lastEnd, RingEnd.taskDone);
      await rig.finish();
    });

    testWidgets('a task out of time leads to Lit key', (tester) async {
      final rig = _Rig(tester);
      await rig.start();
      await rig.ringNow();
      await rig.tapText('Stop');

      await rig.pass(const Duration(seconds: 60));

      expect(rig.run.task, isA<LitKeyTask>());
      await rig.finish();
    });
  });

  group('emergency stop', () {
    testWidgets('holding Stop for 5 s ends the ring, before a task', (
      tester,
    ) async {
      final rig = _Rig(tester);
      await rig.start();
      await rig.ringNow();

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Stop')),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));
      expect(rig.state.phase, TryRingPhase.ringing);
      expect(find.textContaining('Keep holding'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettleSoon();

      expect(rig.state.lastEnd, RingEnd.emergencyStop);
      expect(find.byType(RingingScreen), findsNothing);
      await rig.finish();
    });

    testWidgets('holding the key during a task ends the ring', (tester) async {
      final rig = _Rig(tester);
      await rig.start();
      await rig.ringNow();
      await rig.tapText('Stop');

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Hold 5 s to stop')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 5100));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettleSoon();

      expect(rig.state.lastEnd, RingEnd.emergencyStop);
      await rig.finish();
    });

    testWidgets('a hold let go early is just a press', (tester) async {
      final rig = _Rig(tester);
      await rig.start();
      await rig.ringNow();

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Stop')),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      expect(rig.state.phase, TryRingPhase.ringing);
      expect(rig.run.task, isNotNull);
      await rig.finish();
    });

    testWidgets('a finger that slides a little keeps counting', (tester) async {
      final rig = _Rig(tester);
      await rig.start();
      await rig.ringNow();

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Stop')),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump(const Duration(milliseconds: 3100));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettleSoon();

      expect(rig.state.lastEnd, RingEnd.emergencyStop);
      await rig.finish();
    });

    testWidgets('holding Enter on the key works from a keyboard', (
      tester,
    ) async {
      final rig = _Rig(tester);
      await rig.start();
      await rig.ringNow();
      final key = find.descendant(
        of: find.byType(HoldToStopKey),
        matching: find.byType(FilledButton),
      );
      Focus.of(tester.element(find.text('Stop'))).requestFocus();
      await tester.pump();
      expect(key, findsOneWidget);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 5100));
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettleSoon();

      expect(rig.state.lastEnd, RingEnd.emergencyStop);
      await rig.finish();
    });

    testWidgets('a screen reader gets it as a long press', (tester) async {
      final handle = tester.ensureSemantics();
      final rig = _Rig(tester);
      await rig.start();
      await rig.ringNow();

      final node = tester.getSemantics(find.text('Stop'));
      node.owner!.performAction(node.id, SemanticsAction.longPress);
      await tester.pumpAndSettleSoon();

      expect(rig.state.lastEnd, RingEnd.emergencyStop);
      await rig.finish();
      handle.dispose();
    });
  });

  group('the cap', () {
    testWidgets('ends the ring at 10 minutes and counts it as missed', (
      tester,
    ) async {
      final rig = _Rig(tester);
      await rig.start();
      await rig.ringNow();

      await rig.pass(const Duration(minutes: 9, seconds: 59));
      expect(rig.state.phase, TryRingPhase.ringing);

      await rig.pass(const Duration(seconds: 1));
      await tester.pumpAndSettleSoon();

      expect(rig.state.lastEnd, RingEnd.cap);
      expect(find.byType(RingingScreen), findsNothing);
      expect(find.textContaining('MISSED'), findsOneWidget);
      expect(rig.screen.kept, isFalse);
      await rig.finish();
    });
  });

  group('Snooze', () {
    testWidgets('silences the ring and rings again after 5 minutes', (
      tester,
    ) async {
      final rig = _Rig(tester);
      await rig.start();
      await rig.ringNow();

      await rig.tapText('Snooze');
      await tester.pumpAndSettleSoon();

      expect(rig.state.phase, TryRingPhase.waiting);
      expect(rig.player.stops, greaterThan(0));
      expect(find.byType(RingingScreen), findsNothing);
      expect(find.text('05:00'), findsOneWidget);
      expect(rig.screen.kept, isTrue);

      await rig.pass(const Duration(minutes: 1));
      expect(find.text('04:00'), findsOneWidget);

      await rig.pass(const Duration(minutes: 4));
      await tester.pumpAndSettleSoon();

      expect(find.byType(RingingScreen), findsOneWidget);
      await rig.finish();
    });
  });
}

extension on WidgetTester {
  /// Lets the page transitions end. `pumpAndSettle` would never return while
  /// a ring's ticker keeps asking for frames.
  Future<void> pumpAndSettleSoon() async {
    for (var i = 0; i < 12; i++) {
      await pump(const Duration(milliseconds: 100));
    }
  }
}
