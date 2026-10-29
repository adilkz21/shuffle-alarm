import 'package:meta/meta.dart';

/// Something an alarm can play: a clip from the library, a song the user
/// imported, or a voice message.
@immutable
final class Sound {
  new({
    required this.id,
    required this.title,
    required this.source,
    required this.genre,
    required this.intensity,
    required this.duration,
    this.clipStart = Duration.zero,
  }) : assert(duration > Duration.zero, 'duration must be positive'),
       assert(
         !clipStart.isNegative && clipStart < duration,
         'clipStart must be inside the sound',
       );

  /// For a library clip, its id in `manifest.json`.
  final String id;

  /// Shown while it plays; for a voice message, the name the user gave it.
  final String title;

  final SoundSource source;

  /// A genre id, such as `lofi`; alarms choose sounds by genre.
  final String genre;

  final Intensity intensity;

  /// The length of the whole audio file.
  final Duration duration;

  /// Where in the file the alarm starts playing; users choose it for their
  /// own songs.
  final Duration clipStart;

  @override
  bool operator ==(Object other) =>
      other is Sound &&
      other.id == id &&
      other.title == title &&
      other.source == source &&
      other.genre == genre &&
      other.intensity == intensity &&
      other.duration == duration &&
      other.clipStart == clipStart;

  @override
  int get hashCode =>
      Object.hash(id, title, source, genre, intensity, duration, clipStart);

  @override
  String toString() =>
      'Sound($id, $title, ${source.name}, $genre, ${intensity.name}, '
      'duration: $duration, clipStart: $clipStart)';
}

/// Where a sound comes from.
enum SoundSource {
  /// Bundled with the app: the library.
  builtin,

  /// A song the user imported. It stays on the device.
  user,

  /// A voice message the user recorded or imported. It stays on the device.
  voice,
}

/// How strong a sound is, from gentle to strong. Escalation plays them in
/// this order.
enum Intensity {
  /// Soft and melodic.
  gentle(1),
  medium(2),
  strong(3);

  new(this.level);

  /// 1 to 3, as in the library manifest.
  final int level;
}
