import 'dart:math';

import 'package:collection/collection.dart';
import 'package:shuffle_alarm/core/sound.dart';

/// The kinds of wake-up task.
enum WakeUpTaskKind { whichSound, catchTheChange, move, litKey }

/// How far a wake-up task has come. A task only ever leaves [running] once.
enum WakeUpTaskStatus {
  running,

  /// The task was finished, so the ring can stop.
  done,

  /// The time limit ran out; the ring goes on with the easier fallback.
  timedOut,
}

/// What a task made of an answer, a tap or a press.
enum TaskResponse {
  right,
  wrong,

  /// It didn't count at all, for example a second tap on the same switch.
  ignored,
}

/// The tasks Stop can start, given the [sounds] of the library and whether
/// the device has a motion sensor. Never empty: when nothing else is
/// possible, it is the Lit key task. Sounds with the same id count as one.
List<WakeUpTaskKind> possibleWakeUpTasks(
  Iterable<Sound> sounds, {
  required bool hasMotionSensor,
}) {
  final titlesById = {for (final sound in sounds) sound.id: sound.title};
  final titles = titlesById.values.toSet();
  final kinds = <WakeUpTaskKind>[
    if (titles.length >= WhichSoundTask.optionCount) .whichSound,
    if (titlesById.length >= 2) .catchTheChange,
    if (hasMotionSensor) .move,
  ];
  return kinds.isEmpty ? const [.litKey] : kinds;
}

/// A short task that Stop opens while the sounds keep rotating. It holds the
/// rules only: the ringing code gives it the time, the taps and the sensor
/// readings, and plays the sounds it asks for.
///
/// Every time is measured from the start of the ring on one `Stopwatch`, so
/// changing the clock can't end a task, and a throttled browser tab only
/// makes the updates late, not wrong. A task never locks anyone in: at its
/// time limit it ends as [WakeUpTaskStatus.timedOut], and [easierFallback]
/// can be taken at any moment, while the ring cap and the emergency stop
/// stay with the ringing code.
sealed class WakeUpTask {
  new({required this.startedAt, required this._random});

  /// When the task began.
  final Duration startedAt;

  final Random _random;

  WakeUpTaskKind get kind;

  /// How long the task may take.
  Duration get timeLimit;

  /// When the time limit runs out.
  Duration get deadline => startedAt + timeLimit;

  WakeUpTaskStatus get status => _status;
  WakeUpTaskStatus _status = .running;

  /// How many wrong answers, taps or presses there were.
  int get mistakes => _mistakes;
  var _mistakes = 0;

  /// How much is done so far, out of [progressNeeded].
  int get progress;

  int get progressNeeded;

  /// Whether the ringing code should start the next sound now, and then call
  /// [soundChanged].
  bool get wantsNewSound => false;

  /// Tells the task a new sound began at [now]: one it asked for, or the next
  /// clip after the last one ended. Sound tasks need [now] to be the moment
  /// the sound really started.
  void soundChanged(Sound sound, Duration now) => update(now);

  /// Tells the task the time. Every other call does this too; the ringing
  /// code calls it on each tick, so the time limit runs out without a tap.
  void update(Duration now) {
    if (_status == .running && now >= deadline) _status = .timedOut;
  }

  /// The easier task to go on with from [now]. It needs neither hearing nor
  /// movement, and a Lit key that timed out is followed by a new one.
  LitKeyTask easierFallback(Duration now) =>
      LitKeyTask(random: _random, startedAt: now);
}

/// "Which sound is playing?": pick the playing sound among [optionCount]
/// titles, [answersNeeded] times in a row. Each answer asks for a new sound
/// and each new sound opens a new round, so no round repeats the last one's
/// answer. The ringing screen must hide the sound's title during this task.
final class WhichSoundTask extends WakeUpTask {
  /// A task that takes the other titles it offers from [sounds].
  ///
  /// Until the first new sound starts, it offers nothing: a round should not
  /// open on a clip that is about to end.
  new({
    required Iterable<Sound> sounds,
    required super.random,
    required super.startedAt,
  }) : _sounds = sounds.sortedBy((sound) => sound.id);

  static const optionCount = 3;
  static const answersNeeded = 3;

  /// The pool in id order, so the same seed gives the same options, whatever
  /// order the pool comes in.
  final List<Sound> _sounds;

  Sound? _playing;
  var _inARow = 0;
  var _awaitingSound = true;
  var _options = const <Sound>[];

  @override
  WakeUpTaskKind get kind => .whichSound;

  @override
  Duration get timeLimit => const Duration(seconds: 60);

  @override
  int get progress => _inARow;

  @override
  int get progressNeeded => answersNeeded;

  @override
  bool get wantsNewSound => status == .running && _awaitingSound;

  /// The sounds to choose from, in the order of the keys. It holds the
  /// playing sound and sounds with other titles, so no two keys read the
  /// same; with too few titles in the pool, it holds fewer than
  /// [optionCount]. The list can't be changed.
  List<Sound> get options => _options;

  @override
  void soundChanged(Sound sound, Duration now) {
    update(now);
    if (status != .running) return;
    _playing = sound;
    _awaitingSound = false;
    final titles = {sound.title};
    final decoys = _sounds
        .shuffled(_random)
        .where((other) => titles.add(other.title))
        .take(optionCount - 1);
    _options = List.unmodifiable([sound, ...decoys].shuffled(_random));
  }

  /// Answers that [choice] is playing. A wrong answer starts the count again.
  /// While the new sound is on its way there is no round to answer, so a
  /// second tap is ignored.
  TaskResponse answer(Sound choice, Duration now) {
    update(now);
    if (status != .running || _awaitingSound) return .ignored;
    _awaitingSound = true;
    if (choice.id != _playing?.id) {
      _mistakes++;
      _inARow = 0;
      return .wrong;
    }
    _inARow++;
    if (_inARow >= answersNeeded) _status = .done;
    return .right;
  }
}

/// "Catch the change": the sounds switch at random moments; tap within
/// [tapWindow] of a switch, [catchesNeeded] times. A tap at any other moment
/// takes back one catch, so tapping blindly never finishes the task. Missing
/// a switch costs nothing.
final class CatchTheChangeTask extends WakeUpTask {
  new({required super.random, required super.startedAt}) {
    _nextSwitch = startedAt + _randomGap();
  }

  static const catchesNeeded = 3;
  static const tapWindow = Duration(milliseconds: 1500);

  /// The shortest time between switches: longer than [tapWindow], so one tap
  /// can never be meant for two switches.
  static const minGap = Duration(seconds: 4);
  static const maxGap = Duration(seconds: 10);

  late Duration _nextSwitch;
  Duration? _lastSwitch;
  var _caughtLastSwitch = false;
  var _switchDue = false;
  var _catches = 0;

  @override
  WakeUpTaskKind get kind => .catchTheChange;

  @override
  Duration get timeLimit => const Duration(seconds: 60);

  @override
  int get progress => _catches;

  @override
  int get progressNeeded => catchesNeeded;

  @override
  bool get wantsNewSound => status == .running && _switchDue;

  @override
  void update(Duration now) {
    super.update(now);
    _switchDue = now >= _nextSwitch;
  }

  /// Any new sound is a switch that can be caught, also a clip that just
  /// ended. The next switch is planned from here.
  @override
  void soundChanged(Sound sound, Duration now) {
    update(now);
    _lastSwitch = now;
    _caughtLastSwitch = false;
    _switchDue = false;
    _nextSwitch = now + _randomGap();
  }

  /// Taps the key. A second tap on a switch already caught is ignored, so a
  /// double tap costs nothing.
  TaskResponse tap(Duration now) {
    update(now);
    if (status != .running) return .ignored;
    final lastSwitch = _lastSwitch;
    if (lastSwitch == null || now - lastSwitch > tapWindow) {
      _mistakes++;
      if (_catches > 0) _catches--;
      return .wrong;
    }
    if (_caughtLastSwitch) return .ignored;
    _caughtLastSwitch = true;
    _catches++;
    if (_catches >= catchesNeeded) _status = .done;
    return .right;
  }

  Duration _randomGap() {
    final range = (maxGap - minGap).inMilliseconds;
    return minGap + Duration(milliseconds: _random.nextInt(range + 1));
  }
}

/// "Move": [secondsNeeded] seconds of movement, with pauses allowed. A second
/// counts when the strength of the readings changes by at least
/// [movementThreshold] within it. Comparing strengths inside one second works
/// with or without gravity in the readings, at any sensor rate of a few
/// readings a second and up, and ignores a phone that lies still or is only
/// turned slowly.
final class MoveTask extends WakeUpTask {
  new({required super.random, required super.startedAt});

  static const secondsNeeded = 30;

  /// In m/s². A start value: walking swings about 3 to 8, a phone at rest
  /// well under 1. Tune it with the tests on people.
  static const movementThreshold = 2.0;

  var _movedSeconds = 0;

  /// The second being measured, counted from the start of the task.
  var _second = 0;
  double _weakest = double.infinity;
  double _strongest = double.negativeInfinity;

  @override
  WakeUpTaskKind get kind => .move;

  @override
  Duration get timeLimit => const Duration(seconds: 90);

  @override
  int get progress => _movedSeconds;

  @override
  int get progressNeeded => secondsNeeded;

  /// A second counts once it is over, so 30 s of movement take a full 30 s.
  /// A second that ended by the time limit still counts when the update comes
  /// late.
  @override
  void update(Duration now) {
    if (status != .running) return;
    final second = (now - startedAt).inSeconds;
    if (second > _second) {
      if (_strongest - _weakest >= movementThreshold) _movedSeconds++;
      _second = second;
      _weakest = double.infinity;
      _strongest = double.negativeInfinity;
      if (_movedSeconds >= secondsNeeded) _status = .done;
    }
    super.update(now);
  }

  /// One reading of the motion sensor, in m/s². Readings that aren't numbers
  /// are skipped.
  void reading(double x, double y, double z, Duration now) {
    update(now);
    final strength = sqrt(x * x + y * y + z * z);
    if (!strength.isFinite) return;
    _weakest = min(_weakest, strength);
    _strongest = max(_strongest, strength);
  }
}

/// The easier fallback: press the lit key among [keyCount], [pressesNeeded]
/// times. It takes no hearing, no movement of the phone and no speed. A wrong
/// key only counts as a mistake. The light never stays on the same key, so
/// the task takes a look at the screen each time.
final class LitKeyTask extends WakeUpTask {
  new({required super.random, required super.startedAt}) {
    _litKey = _random.nextInt(keyCount);
  }

  static const keyCount = 3;
  static const pressesNeeded = 5;

  late int _litKey;
  var _presses = 0;

  /// Which key is lit: 0 to [keyCount] - 1.
  int get litKey => _litKey;

  @override
  WakeUpTaskKind get kind => .litKey;

  @override
  Duration get timeLimit => const Duration(seconds: 60);

  @override
  int get progress => _presses;

  @override
  int get progressNeeded => pressesNeeded;

  /// Presses [key].
  TaskResponse press(int key, Duration now) {
    update(now);
    if (status != .running) return .ignored;
    if (key != _litKey) {
      _mistakes++;
      return .wrong;
    }
    _presses++;
    if (_presses >= pressesNeeded) _status = .done;
    _litKey = (_litKey + 1 + _random.nextInt(keyCount - 1)) % keyCount;
    return .right;
  }
}
