import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:shuffle_alarm/core/ring_event.dart';

/// One time an alarm rang: from its first sound until Stop, Snooze or the
/// ring cap. The ring after a Snooze is a new session.
@immutable
final class RingSession {
  new({
    required this.id,
    required this.alarmId,
    required this.dueAt,
    required this.startedAt,
    List<RingEvent> events = const [],
  }) : assert(
         events.reversed.skip(1).every((event) => event.action == .timeout),
         'only the last sound can end with Stop or Snooze',
       ),
       events = List.unmodifiable(events);

  final String id;
  final String alarmId;

  /// When the alarm was due. A ring after a Snooze keeps the first ring's
  /// time, so all rings of one morning share it.
  final DateTime dueAt;

  /// When it started ringing: later than [dueAt] after a Snooze, or when
  /// the alarm was late (for example in a background browser tab).
  final DateTime startedAt;

  /// The sounds in the order they played. Only the last one can end with
  /// Stop or Snooze.
  final List<RingEvent> events;

  /// When the last sound ended; null until a sound has finished.
  DateTime? get endedAt => events.lastOrNull?.endedAt;

  /// How it ended. Without Stop or Snooze it counts as missed: the ring cap
  /// ran out, or the app was closed while it rang.
  RingOutcome get outcome => switch (events.lastOrNull?.action) {
    .stop => .stopped,
    .snooze => .snoozed,
    .timeout || null => .missed,
  };

  @override
  bool operator ==(Object other) =>
      other is RingSession &&
      other.id == id &&
      other.alarmId == alarmId &&
      other.dueAt == dueAt &&
      other.startedAt == startedAt &&
      const ListEquality<RingEvent>().equals(other.events, events);

  @override
  int get hashCode => Object.hash(
    id,
    alarmId,
    dueAt,
    startedAt,
    const ListEquality<RingEvent>().hash(events),
  );

  @override
  String toString() =>
      'RingSession($id, alarm: $alarmId, dueAt: $dueAt, '
      'startedAt: $startedAt, outcome: ${outcome.name}, events: $events)';
}

/// How a ring ended.
enum RingOutcome { stopped, snoozed, missed }
