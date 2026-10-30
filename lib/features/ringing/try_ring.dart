import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:shuffle_alarm/core/alarm.dart';
import 'package:shuffle_alarm/core/ring_run.dart';
import 'package:shuffle_alarm/core/sound.dart';
import 'package:shuffle_alarm/core/sound_clip.dart';
import 'package:shuffle_alarm/core/wake_up_task.dart';
import 'package:shuffle_alarm/data/sound_library.dart';
import 'package:shuffle_alarm/platform/motion_sensor.dart';
import 'package:shuffle_alarm/platform/screen_awake.dart';
import 'package:shuffle_alarm/platform/sound_player.dart';

/// How long Snooze waits, until the setting comes.
const snoozeTime = Duration(minutes: 5);

/// What plays when the library has no sound to give, because an alarm must
/// never ring silently (D13). The library plays this file too, so it ships.
const _fallbackAsset = 'assets/library/placeholder/alarm-clock.wav';
final _fallbackSound = Sound(
  id: 'fallback',
  title: 'Alarm',
  source: .builtin,
  genre: 'fallback',
  intensity: .strong,
  duration: const Duration(seconds: 24),
);

/// How often the clock is checked. Fast enough for "Catch the change", and a
/// throttled background tab only makes it later, not wrong (D16).
const _tickEvery = Duration(milliseconds: 200);

/// The sounds of the app. An override gives tests their own.
final soundLibraryProvider = FutureProvider<SoundLibrary>(
  (ref) => loadSoundLibrary(rootBundle.loadString),
);

/// Makes the stopwatch of a ring. An override lets tests move time.
final ringStopwatchProvider = Provider<Stopwatch Function()>(
  (ref) => Stopwatch.new,
);

/// The randomness of rings. An override gives tests a seed.
final ringRandomProvider = Provider<Random>((ref) => Random());

enum TryRingPhase {
  /// Nothing is on its way.
  idle,

  /// A ring comes at a moment the screen doesn't show, or after a Snooze.
  waiting,

  ringing,
}

/// What the screens show of a try. It is replaced on every tick, so widgets
/// that watch it stay current.
@immutable
final class TryRingState {
  const new({
    this.phase = .idle,
    this.run,
    this.now = Duration.zero,
    this.lastEnd,
    this.snoozeLeft,
    this.lastResponse,
  });

  final TryRingPhase phase;

  /// The ring now going on; null unless [phase] is ringing.
  final RingRun? run;

  /// The time on the ring's stopwatch.
  final Duration now;

  /// How the last ring ended; null before the first.
  final RingEnd? lastEnd;

  /// How long until a snoozed ring comes back; null for any other wait.
  final Duration? snoozeLeft;

  /// What the running task made of the last answer, tap or press.
  final TaskResponse? lastResponse;
}

/// One "Try a ring": it waits, plays the sounds a [RingRun] asks for, and
/// hands it the time, the taps and the sensor readings. Why:
/// docs/DECISIONS.md (D17).
final tryRingProvider = NotifierProvider<TryRing, TryRingState>(TryRing.new);

final class TryRing extends Notifier<TryRingState> {
  Timer? _ticker;
  Stopwatch? _clock;
  Duration _dueAt = Duration.zero;
  Duration? _snoozeDueAt;
  RingRun? _run;
  SoundLibrary? _library;
  WakeUpTaskPicker? _picker;
  StreamSubscription<void>? _endedSubscription;
  StreamSubscription<MotionReading>? _motionSubscription;
  var _hasMotionSensor = false;
  TaskResponse? _lastResponse;

  SoundPlayer get _player => ref.read(soundPlayerProvider);
  MotionSensor get _motion => ref.read(motionSensorProvider);
  ScreenAwake get _screen => ref.read(screenAwakeProvider);
  Random get _random => ref.read(ringRandomProvider);

  @override
  TryRingState build() {
    ref.onDispose(_closeRing);
    return const TryRingState();
  }

  /// Rings now. Call it straight from a tap, which lets the sounds play.
  Future<void> ringNow() => _begin(Duration.zero);

  /// Rings at a random moment in the next 5 minutes. Call it straight from a
  /// tap, which lets the sounds play when the moment comes.
  Future<void> ringAtRandomMoment() => _begin(randomTryRingDelay(_random));

  Future<void> _begin(Duration delay) async {
    if (state.phase != .idle) return;
    unawaited(_player.unlock());
    unawaited(_screen.keepOn());
    unawaited(_findMotionSensor());
    _clock = ref.read(ringStopwatchProvider)()..start();
    _dueAt = delay;
    state = TryRingState(phase: .waiting, lastEnd: state.lastEnd);
    final library = await ref.read(soundLibraryProvider.future);
    _library = library;
    unawaited(_player.preload(library.entries.map((entry) => entry.asset)));
    if (state.phase != .waiting) return;
    _ticker ??= Timer.periodic(_tickEvery, (_) => _tick());
    _tick();
  }

  Future<void> _findMotionSensor() async {
    _hasMotionSensor = await _motion.isAvailable();
  }

  /// Calls off a ring that is on its way.
  void cancelWaiting() {
    if (state.phase != .waiting) return;
    _closeRing();
    unawaited(_screen.allowOff());
    _snoozeDueAt = null;
    state = TryRingState(lastEnd: state.lastEnd);
  }

  void pressStop() {
    final run = _run;
    if (run == null || run.task != null) return;
    final kind = (_picker ??= WakeUpTaskPicker(_random)).next(
      possibleWakeUpTasks(
        _library?.sounds ?? const [],
        hasMotionSensor: _hasMotionSensor,
      ),
    );
    run.pressStop(kind, _elapsed);
    _tick();
  }

  void snooze() {
    _run?.snooze(_elapsed);
    _tick();
  }

  void emergencyStop() {
    _run?.emergencyStop(_elapsed);
    _tick();
  }

  void takeEasierTask() {
    _run?.takeEasierTask(_elapsed);
    _lastResponse = null;
    _tick();
  }

  /// The answer to "Which sound is playing?".
  void answerWhichSound(Sound choice) {
    if (_run?.task case final WhichSoundTask task) {
      _respond(task.answer(choice, _elapsed));
    }
  }

  /// The tap of "Catch the change".
  void tapCatchTheChange() {
    if (_run?.task case final CatchTheChangeTask task) {
      _respond(task.tap(_elapsed));
    }
  }

  /// The press of a key in "Lit key".
  void pressLitKey(int key) {
    if (_run?.task case final LitKeyTask task) {
      _respond(task.press(key, _elapsed));
    }
  }

  /// A tap that lets sounds play again when the browser blocked them.
  void turnSoundOn() {
    unawaited(_player.unlock());
  }

  void _respond(TaskResponse response) {
    if (response != .ignored) _lastResponse = response;
    _tick();
  }

  Duration get _elapsed => _clock?.elapsed ?? Duration.zero;

  void _tick() {
    if (_run == null) {
      if (state.phase != .waiting) return;
      if (_elapsed >= _dueAt) {
        _startRing();
      } else {
        _publishWaiting();
      }
      return;
    }
    final run = _run!;
    final now = _elapsed;
    run.update(now);
    if (run.isOver) {
      _finishRing(run);
      return;
    }
    if (run.wantsNextClip) unawaited(_playNextClip(run));
    _followMotion(run);
    state = TryRingState(
      phase: .ringing,
      run: run,
      now: now,
      lastEnd: state.lastEnd,
      lastResponse: _lastResponse,
    );
  }

  void _publishWaiting() {
    final snoozeDueAt = _snoozeDueAt;
    if (snoozeDueAt == null) return;
    state = TryRingState(
      phase: .waiting,
      lastEnd: state.lastEnd,
      snoozeLeft: snoozeDueAt - _elapsed,
    );
  }

  void _startRing() {
    _snoozeDueAt = null;
    _lastResponse = null;
    _clock = ref.read(ringStopwatchProvider)()..start();
    final run = _run = RingRun(
      alarm: Alarm(id: 'try-a-ring', time: const AlarmTime(0, 0)),
      pool: _library?.sounds ?? const [],
      fallback: _fallbackSound,
      random: _random,
    );
    _endedSubscription = _player.onEnded.listen((_) {
      run.clipEnded(_elapsed);
      _tick();
    });
    _tick();
  }

  Future<void> _playNextClip(RingRun run) async {
    final clip = run.beginNextClip();
    try {
      await _player.play(_assetOf(clip), start: clip.start);
      if (run.isOver) {
        unawaited(_player.stop());
        return;
      }
      run.clipStarted(_elapsed);
    } on Object catch (_) {
      // The browser blocked it or the file can't load: the screen says so,
      // and the next sound gets its turn.
      run.clipFailed(_elapsed);
    }
    _tick();
  }

  String _assetOf(SoundClip clip) {
    for (final entry in _library?.entries ?? const <LibraryEntry>[]) {
      if (entry.sound.id == clip.sound.id) return entry.asset;
    }
    return _fallbackAsset;
  }

  /// Listens to the sensor only while "Move" runs.
  void _followMotion(RingRun run) {
    final task = run.task;
    if (task is! MoveTask) {
      unawaited(_motionSubscription?.cancel());
      _motionSubscription = null;
      return;
    }
    _motionSubscription ??= _motion.readings.listen((reading) {
      final current = _run?.task;
      if (current is MoveTask) {
        current.reading(reading.x, reading.y, reading.z, _elapsed);
      }
    });
  }

  void _finishRing(RingRun run) {
    _closeRing();
    unawaited(_player.stop());
    final end = run.end;
    if (end == .snoozed) {
      _clock = ref.read(ringStopwatchProvider)()..start();
      _dueAt = snoozeTime;
      _snoozeDueAt = snoozeTime;
      _ticker = Timer.periodic(_tickEvery, (_) => _tick());
      state = TryRingState(
        phase: .waiting,
        lastEnd: end,
        snoozeLeft: snoozeTime,
      );
      return;
    }
    unawaited(_screen.allowOff());
    state = TryRingState(lastEnd: end);
  }

  void _closeRing() {
    _ticker?.cancel();
    _ticker = null;
    unawaited(_endedSubscription?.cancel());
    _endedSubscription = null;
    unawaited(_motionSubscription?.cancel());
    _motionSubscription = null;
    _run = null;
    _lastResponse = null;
  }
}
