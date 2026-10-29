import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// An alarm the user set: when it rings and what it may play.
@immutable
final class Alarm {
  new({
    required this.id,
    required this.time,
    Set<Weekday> repeatDays = const {},
    this.label = '',
    this.enabled = true,
    Set<String> genres = const {},
    this.gentleStart = true,
    this.experimentGroup,
  }) : repeatDays = Set.unmodifiable(repeatDays),
       genres = Set.unmodifiable(genres);

  final String id;

  final AlarmTime time;

  /// The days it rings on; empty for an alarm that rings once.
  final Set<Weekday> repeatDays;

  /// The user's name for it, such as "Gym"; may be empty.
  final String label;

  final bool enabled;

  /// The genres it plays (`Sound.genre`). Empty means every genre, so an
  /// alarm always has sounds to play.
  final Set<String> genres;

  /// Opens with a gentle sound and gets stronger.
  final bool gentleStart;

  /// Its group while the wake-up experiment runs, otherwise null.
  final ExperimentGroup? experimentGroup;

  /// Whether it may play sounds of [genre].
  bool playsGenre(String genre) => genres.isEmpty || genres.contains(genre);

  @override
  bool operator ==(Object other) =>
      other is Alarm &&
      other.id == id &&
      other.time == time &&
      const SetEquality<Weekday>().equals(other.repeatDays, repeatDays) &&
      other.label == label &&
      other.enabled == enabled &&
      const SetEquality<String>().equals(other.genres, genres) &&
      other.gentleStart == gentleStart &&
      other.experimentGroup == experimentGroup;

  @override
  int get hashCode => Object.hash(
    id,
    time,
    const SetEquality<Weekday>().hash(repeatDays),
    label,
    enabled,
    const SetEquality<String>().hash(genres),
    gentleStart,
    experimentGroup,
  );

  @override
  String toString() =>
      'Alarm($id, $time, repeatDays: $repeatDays, label: $label, '
      'enabled: $enabled, genres: $genres, gentleStart: $gentleStart, '
      'experimentGroup: $experimentGroup)';
}

/// A time of day on the wall clock, such as 07:30.
@immutable
final class AlarmTime implements Comparable<AlarmTime> {
  const new(this.hour, this.minute)
    : assert(hour >= 0 && hour < 24, 'hour must be 0 to 23'),
      assert(minute >= 0 && minute < 60, 'minute must be 0 to 59');

  final int hour;
  final int minute;

  int get _minutesSinceMidnight => hour * 60 + minute;

  @override
  int compareTo(AlarmTime other) =>
      _minutesSinceMidnight.compareTo(other._minutesSinceMidnight);

  @override
  bool operator ==(Object other) =>
      other is AlarmTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  /// `HH:mm`, such as `07:05`.
  @override
  String toString() => '${_twoDigits(hour)}:${_twoDigits(minute)}';
}

/// A day of the week, in the order of [DateTime.weekday]: Monday first.
enum Weekday {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  /// The day of the week [date] falls on.
  factory of(DateTime date) => values[date.weekday - 1];
}

/// The two halves of the wake-up experiment.
enum ExperimentGroup {
  /// The same sound every morning.
  sameSound,

  /// Rotating sounds, as usual.
  rotation,
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');
