import 'package:flutter_test/flutter_test.dart';
import 'package:shuffle_alarm/core/ring_event.dart';

RingEvent _event({
  String soundId = 'lofi-01',
  DateTime? startedAt,
  DateTime? endedAt,
  RingAction action = .timeout,
}) => RingEvent(
  soundId: soundId,
  startedAt: startedAt ?? DateTime(2026, 10, 29, 7),
  endedAt: endedAt ?? DateTime(2026, 10, 29, 7, 0, 30),
  action: action,
);

void main() {
  test('equals an event with the same values', () {
    expect(_event(), _event());
    expect(_event().hashCode, _event().hashCode);
  });

  test('differs when any value differs', () {
    final event = _event();
    final others = [
      _event(soundId: 'lofi-02'),
      _event(startedAt: DateTime(2026, 10, 29, 7, 0, 1)),
      _event(endedAt: DateTime(2026, 10, 29, 7, 0, 29)),
      _event(action: .stop),
    ];

    for (final other in others) {
      expect(other, isNot(event));
    }
  });
}
