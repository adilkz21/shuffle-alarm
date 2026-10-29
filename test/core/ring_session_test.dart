import 'package:flutter_test/flutter_test.dart';
import 'package:shuffle_alarm/core/ring_event.dart';
import 'package:shuffle_alarm/core/ring_session.dart';

final _seven = DateTime(2026, 10, 29, 7);

/// A sound that started [second] seconds after 07:00 and played for 30 s.
RingEvent _played(int second, RingAction action) => RingEvent(
  soundId: 'sound-$second',
  startedAt: _seven.add(Duration(seconds: second)),
  endedAt: _seven.add(Duration(seconds: second + 30)),
  action: action,
);

RingSession _session({
  String id = 's1',
  String alarmId = 'a1',
  DateTime? dueAt,
  DateTime? startedAt,
  List<RingEvent> events = const [],
}) => RingSession(
  id: id,
  alarmId: alarmId,
  dueAt: dueAt ?? _seven,
  startedAt: startedAt ?? _seven,
  events: events,
);

void main() {
  test('is stopped when the user taps Stop', () {
    final stop = _played(60, .stop);
    final session = _session(
      events: [_played(0, .timeout), _played(30, .timeout), stop],
    );

    expect(session.outcome, RingOutcome.stopped);
    expect(session.endedAt, stop.endedAt);
  });

  test('is snoozed when the user taps Snooze', () {
    final session = _session(events: [_played(0, .snooze)]);

    expect(session.outcome, RingOutcome.snoozed);
  });

  test('is missed when nobody taps Stop or Snooze', () {
    // 20 sounds of 30 s fill the 10-minute cap.
    final session = _session(
      events: [for (var i = 0; i < 20; i++) _played(i * 30, .timeout)],
    );

    expect(session.outcome, RingOutcome.missed);
    expect(session.endedAt, _seven.add(const Duration(minutes: 10)));
  });

  test('is missed, with no end time, when no sound finished', () {
    final session = _session();

    expect(session.outcome, RingOutcome.missed);
    expect(session.endedAt, isNull);
  });

  test('only the last sound can end with Stop or Snooze', () {
    for (final events in [
      [_played(0, .stop), _played(30, .timeout)],
      [_played(0, .snooze), _played(30, .stop)],
    ]) {
      expect(() => _session(events: events), throwsAssertionError);
    }
  });

  test('keeps its own copy of the events, in order, which cannot change', () {
    final first = _played(0, .timeout);
    final second = _played(30, .stop);
    final events = [first, second];
    final session = _session(events: events);

    events.clear();

    expect(session.events, [first, second]);
    expect(() => session.events.add(first), throwsUnsupportedError);
  });

  test('equals a session with the same values', () {
    final session = _session(
      events: [_played(0, .timeout), _played(30, .stop)],
    );
    final same = _session(events: [_played(0, .timeout), _played(30, .stop)]);

    expect(same, session);
    expect(same.hashCode, session.hashCode);
  });

  test('differs when any value differs', () {
    final stopped = [_played(0, .stop)];
    final session = _session(events: stopped);
    final others = [
      _session(id: 's2', events: stopped),
      _session(alarmId: 'a2', events: stopped),
      _session(dueAt: _seven.add(const Duration(minutes: 5)), events: stopped),
      _session(
        startedAt: _seven.add(const Duration(seconds: 40)),
        events: stopped,
      ),
      _session(events: [_played(0, .snooze)]),
      _session(),
    ];

    for (final other in others) {
      expect(other, isNot(session));
    }
  });
}
