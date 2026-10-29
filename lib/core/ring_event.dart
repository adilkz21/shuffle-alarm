import 'package:meta/meta.dart';

/// One sound played while an alarm rang, and how its turn ended.
@immutable
final class RingEvent {
  const new({
    required this.soundId,
    required this.startedAt,
    required this.endedAt,
    required this.action,
  });

  final String soundId;
  final DateTime startedAt;
  final DateTime endedAt;
  final RingAction action;

  @override
  bool operator ==(Object other) =>
      other is RingEvent &&
      other.soundId == soundId &&
      other.startedAt == startedAt &&
      other.endedAt == endedAt &&
      other.action == action;

  @override
  int get hashCode => Object.hash(soundId, startedAt, endedAt, action);

  @override
  String toString() =>
      'RingEvent($soundId, ${action.name}, $startedAt to $endedAt)';
}

/// How a sound's turn ended.
enum RingAction {
  /// The user tapped Stop.
  stop,

  /// The user tapped Snooze.
  snooze,

  /// Nobody tapped anything: the clip played to its end, or the ring cap
  /// ran out.
  timeout,
}
