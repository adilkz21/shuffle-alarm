import 'dart:math';

import 'package:shuffle_alarm/core/alarm.dart';
import 'package:shuffle_alarm/core/ring_sequence.dart';
import 'package:shuffle_alarm/core/sound.dart';
import 'package:shuffle_alarm/core/sound_clip.dart';
import 'package:shuffle_alarm/core/wake_up_task.dart';

/// How a ring ended.
enum RingEnd {
  /// The wake-up task was finished.
  taskDone,

  /// Stop was held for 5 s.
  emergencyStop,

  /// The ring cap ran out, so it counts as missed.
  cap,

  /// It rings again after the snooze time.
  snoozed,
}

/// How long to wait before another try when a sound fails to play.
const _retryAfter = Duration(seconds: 1);

/// The rules of one ring: which clip comes next, the wake-up task and every
/// way to end. It holds no timers, sound or sensor code: the ringing code
/// gives it the time on one `Stopwatch`, as wake-up tasks expect (D16), and
/// plays the clips it asks for. Why: docs/DECISIONS.md (D17).
final class RingRun {
  /// A ring of an alarm with sounds from a pool. When none of them can play,
  /// it plays the fallback, because an alarm must never ring silently.
  new({
    required this._alarm,
    required Iterable<Sound> pool,
    required this._fallback,
    required this._random,
    this.cap = defaultRingCap,
  }) : _pool = List.unmodifiable(pool);

  final Alarm _alarm;
  final List<Sound> _pool;
  final Sound _fallback;
  final Random _random;

  /// When the ring ends by itself and counts as missed.
  final Duration cap;

  var _planned = const <SoundClip>[];
  var _nextPlanned = 0;
  SoundClip? _lastTaken;
  SoundClip? _loading;
  Duration? _clipEndsAt;
  Duration? _retryAt;
  var _clipEnded = false;
  var _timeForClip = true;

  /// The clip playing now; null until the first one really started.
  SoundClip? get playing => _playing;
  SoundClip? _playing;

  /// Whether the last clip failed to play, and no other has played since.
  bool get soundFailing => _soundFailing;
  var _soundFailing = false;

  /// The wake-up task Stop started; null before that.
  WakeUpTask? get task => _task;
  WakeUpTask? _task;

  /// How the ring ended; null while it rings.
  RingEnd? get end => _end;
  RingEnd? _end;

  /// When the ring ended; null while it rings.
  Duration? get endedAt => _endedAt;
  Duration? _endedAt;

  bool get isOver => _end != null;

  /// Whether the ringing code should call [beginNextClip] now.
  bool get wantsNextClip =>
      !isOver &&
      _loading == null &&
      (_timeForClip || (_task?.wantsNewSound ?? false));

  /// Whether the screen may show the sound's title. During "Which sound" that
  /// would answer the task.
  bool get showsSoundTitle => _task is! WhichSoundTask;

  /// Whether a harder task is running that [takeEasierTask] can replace.
  bool get canTakeEasierTask => _task != null && _task is! LitKeyTask;

  /// Tells the ring the time. The ringing code calls it on each tick and after
  /// each answer, tap or press.
  void update(Duration now) {
    if (isOver) return;
    final task = _task?..update(now);
    if (task != null && task.status == .done) {
      _finish(.taskDone, now);
      return;
    }
    if (now >= cap) {
      _finish(.cap, now);
      return;
    }
    if (task != null && task.status == .timedOut) {
      _task = task.easierFallback(now);
    }
    if (_loading != null) return;
    final retryAt = _retryAt;
    final clipEndsAt = _clipEndsAt;
    _timeForClip =
        _clipEnded ||
        (retryAt != null
            ? now >= retryAt
            : clipEndsAt == null || now >= clipEndsAt);
  }

  /// Takes the next clip to play, and waits for [clipStarted] or [clipFailed].
  SoundClip beginNextClip() {
    final clip = _takeClip();
    _loading = clip;
    _timeForClip = false;
    return clip;
  }

  /// Tells the ring the clip from [beginNextClip] really started at [now].
  void clipStarted(Duration now) {
    final clip = _loading;
    _loading = null;
    if (isOver || clip == null) return;
    _playing = clip;
    _soundFailing = false;
    _clipEnded = false;
    _retryAt = null;
    _clipEndsAt = now + clip.length;
    _task?.soundChanged(clip.sound, now);
    update(now);
  }

  /// Tells the ring the clip from [beginNextClip] could not play. The next one
  /// gets its turn a moment later, and the ring goes on.
  void clipFailed(Duration now) {
    _loading = null;
    if (isOver) return;
    _soundFailing = true;
    _clipEnded = false;
    _retryAt = now + _retryAfter;
    update(now);
  }

  /// Tells the ring the player reached the end of the clip, which is usually
  /// a moment before the clock would notice.
  void clipEnded(Duration now) {
    if (isOver || _loading != null) return;
    _clipEnded = true;
    update(now);
  }

  /// Stop: starts a task of [kind], unless one is already running.
  void pressStop(WakeUpTaskKind kind, Duration now) {
    if (isOver || _task != null) return;
    _task = switch (kind) {
      .whichSound => WhichSoundTask(
        sounds: _pool,
        random: _random,
        startedAt: now,
      ),
      .catchTheChange => CatchTheChangeTask(random: _random, startedAt: now),
      .move => MoveTask(random: _random, startedAt: now),
      .litKey => LitKeyTask(random: _random, startedAt: now),
    };
    update(now);
  }

  /// Goes on with the easier fallback. It keeps the progress of a fallback
  /// that is already running.
  void takeEasierTask(Duration now) {
    if (isOver || !canTakeEasierTask) return;
    _task = _task!.easierFallback(now);
    update(now);
  }

  /// Ends the ring at once; Stop was held long enough. It always works.
  void emergencyStop(Duration now) => _finish(.emergencyStop, now);

  /// Ends the ring so it can ring again later. Stop has been pressed once a
  /// task runs, so Snooze is gone by then.
  void snooze(Duration now) {
    if (_task == null) _finish(.snoozed, now);
  }

  void _finish(RingEnd end, Duration now) {
    if (isOver) return;
    _end = end;
    _endedAt = now;
  }

  SoundClip _takeClip() {
    if (_nextPlanned >= _planned.length) _planMoreClips();
    final clip = _nextPlanned < _planned.length
        ? _planned[_nextPlanned++]
        : SoundClip.of(_fallback);
    _lastTaken = clip;
    return clip;
  }

  /// Wake-up tasks use up clips faster than the ring planned (D13), so a ring
  /// can run out before the cap. The first new clip is skipped when it would
  /// repeat the last one: the next differs, as no sequence repeats a sound.
  void _planMoreClips() {
    final clips = buildRingSequence(
      _alarm,
      _pool,
      // Not `1 << 32`, which is 0 in a browser.
      _random.nextInt(0x7FFFFFFF),
      cap: cap,
    );
    final repeats =
        clips.length > 1 && clips.first.sound.id == _lastTaken?.sound.id;
    _planned = repeats ? clips.sublist(1) : clips;
    _nextPlanned = 0;
  }
}

/// Picks the task Stop starts. Every possible task comes up once before any
/// comes back, because the test with people wants each task once, and no task
/// comes twice in a row when another is possible.
final class WakeUpTaskPicker {
  new(this._random);

  final Random _random;
  final _shown = <WakeUpTaskKind>{};
  WakeUpTaskKind? _last;

  /// The next task among [possible], which must not be empty.
  WakeUpTaskKind next(List<WakeUpTaskKind> possible) {
    var choices = possible.where((kind) => !_shown.contains(kind)).toList();
    if (choices.isEmpty) {
      _shown.clear();
      choices = possible.where((kind) => kind != _last).toList();
      if (choices.isEmpty) choices = possible;
    }
    final kind = choices[_random.nextInt(choices.length)];
    _shown.add(kind);
    _last = kind;
    return kind;
  }
}

/// The soonest a random "Try a ring" comes: time to put the phone down and
/// lie down.
const minTryRingDelay = Duration(seconds: 20);

/// The latest a random "Try a ring" comes.
const maxTryRingDelay = Duration(minutes: 5);

/// How long a "Try a ring" at a random moment waits.
Duration randomTryRingDelay(Random random) {
  final range = (maxTryRingDelay - minTryRingDelay).inMilliseconds;
  return minTryRingDelay + Duration(milliseconds: random.nextInt(range + 1));
}
