import 'package:flutter_test/flutter_test.dart';
import 'package:shuffle_alarm/core/alarm.dart';

/// Not const, so equal times are still different objects.
AlarmTime _time(int hour, int minute) => AlarmTime(hour, minute);

Alarm _alarm({
  String id = 'a1',
  AlarmTime time = const AlarmTime(6, 30),
  Set<Weekday> repeatDays = const {.monday, .friday},
  String label = 'Gym',
  bool enabled = true,
  Set<String> genres = const {'lofi', 'jazz'},
  bool gentleStart = true,
  ExperimentGroup? experimentGroup = .rotation,
}) => Alarm(
  id: id,
  time: time,
  repeatDays: repeatDays,
  label: label,
  enabled: enabled,
  genres: genres,
  gentleStart: gentleStart,
  experimentGroup: experimentGroup,
);

void main() {
  group('AlarmTime', () {
    test('shows as HH:mm', () {
      expect(const AlarmTime(7, 5).toString(), '07:05');
      expect(const AlarmTime(0, 0).toString(), '00:00');
      expect(const AlarmTime(23, 59).toString(), '23:59');
    });

    test('rejects an hour or minute out of range', () {
      for (final (hour, minute) in [(24, 0), (-1, 0), (7, 60), (7, -1)]) {
        expect(() => _time(hour, minute), throwsAssertionError);
      }
    });

    test('sorts from early to late', () {
      final times = [
        const AlarmTime(7, 30),
        const AlarmTime(6, 45),
        const AlarmTime(7, 5),
      ]..sort();

      expect(times, const [
        AlarmTime(6, 45),
        AlarmTime(7, 5),
        AlarmTime(7, 30),
      ]);
    });

    test('equals the same time of day', () {
      expect(_time(7, 30), _time(7, 30));
      expect(_time(7, 30).hashCode, _time(7, 30).hashCode);
      expect(_time(7, 30), isNot(_time(7, 31)));
      expect(_time(7, 30), isNot(_time(8, 30)));
    });
  });

  group('Weekday', () {
    test('is the day of the week of a date', () {
      // The week from Sunday 25 to Saturday 31 October 2026.
      const week = [
        Weekday.sunday,
        Weekday.monday,
        Weekday.tuesday,
        Weekday.wednesday,
        Weekday.thursday,
        Weekday.friday,
        Weekday.saturday,
      ];
      for (final (i, day) in week.indexed) {
        expect(Weekday.of(DateTime(2026, 10, 25 + i, 7, 30)), day);
      }
    });
  });

  group('Alarm', () {
    test('rings once by default, with gentle start and every genre', () {
      final alarm = Alarm(id: 'a1', time: const AlarmTime(7, 0));

      expect(alarm.repeatDays, isEmpty);
      expect(alarm.label, isEmpty);
      expect(alarm.enabled, isTrue);
      expect(alarm.genres, isEmpty);
      expect(alarm.playsGenre('lofi'), isTrue);
      expect(alarm.playsGenre('rock'), isTrue);
      expect(alarm.gentleStart, isTrue);
      expect(alarm.experimentGroup, isNull);
    });

    test('plays only the chosen genres', () {
      final alarm = _alarm(genres: const {'lofi'});

      expect(alarm.playsGenre('lofi'), isTrue);
      expect(alarm.playsGenre('rock'), isFalse);
    });

    test('keeps its own copy of the sets, which cannot change', () {
      final days = {Weekday.monday};
      final genres = {'lofi'};
      final alarm = _alarm(repeatDays: days, genres: genres);

      days.add(Weekday.sunday);
      genres.add('rock');

      expect(alarm.repeatDays, {Weekday.monday});
      expect(alarm.genres, {'lofi'});
      expect(
        () => alarm.repeatDays.add(Weekday.sunday),
        throwsUnsupportedError,
      );
      expect(() => alarm.genres.add('rock'), throwsUnsupportedError);
    });

    test('equals an alarm with the same values in any order', () {
      final alarm = _alarm();
      final same = _alarm(
        repeatDays: const {.friday, .monday},
        genres: const {'jazz', 'lofi'},
      );

      expect(same, alarm);
      expect(same.hashCode, alarm.hashCode);
    });

    test('differs when any value differs', () {
      final alarm = _alarm();
      final others = [
        _alarm(id: 'a2'),
        _alarm(time: const AlarmTime(6, 31)),
        _alarm(repeatDays: const {.monday}),
        _alarm(label: 'Work'),
        _alarm(enabled: false),
        _alarm(genres: const {'lofi'}),
        _alarm(gentleStart: false),
        _alarm(experimentGroup: .sameSound),
        _alarm(experimentGroup: null),
      ];

      for (final other in others) {
        expect(other, isNot(alarm));
      }
    });
  });
}
