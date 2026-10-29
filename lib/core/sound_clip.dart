import 'package:meta/meta.dart';
import 'package:shuffle_alarm/core/sound.dart';

/// The part of a sound that plays in one turn of a ring: from the sound's
/// clip start to the end of its file, but never longer than the limit for
/// its source. [SoundClip.of] is the only way to make one, so every clip
/// keeps to the limits.
@immutable
final class SoundClip {
  /// The clip [sound] plays in one turn.
  factory of(Sound sound) {
    final Sound(:clipStart, :duration) = sound;
    // Sound's asserts keep the clip start inside the file. Should a bad
    // value get past them in a release build, the clip plays from the
    // beginning, and a sound without length gives an empty clip.
    final start = clipStart.isNegative || clipStart >= duration
        ? Duration.zero
        : clipStart;
    final rest = duration - start;
    final limit = maxLengthFor(sound.source);
    final length = Duration(
      microseconds: rest.inMicroseconds.clamp(0, limit.inMicroseconds),
    );
    return SoundClip._(sound, start, length);
  }

  const new _(this.sound, this.start, this.length);

  /// The longest a sound plays in one turn; then the next sound starts.
  static const maxLength = Duration(seconds: 30);

  /// The longest a sound bundled with the app plays: iOS AlarmKit only
  /// accepts alarm sounds shorter than 30 s.
  static const maxBundledLength = Duration(seconds: 29);

  /// The limit for sounds from [source].
  static Duration maxLengthFor(SoundSource source) => switch (source) {
    .builtin => maxBundledLength,
    .user || .voice => maxLength,
  };

  final Sound sound;

  /// Where in the file the clip starts.
  final Duration start;

  /// How long it plays: at most the limit for the sound's source.
  final Duration length;

  /// Where in the file the clip ends.
  Duration get end => start + length;

  @override
  bool operator ==(Object other) =>
      other is SoundClip &&
      other.sound == sound &&
      other.start == start &&
      other.length == length;

  @override
  int get hashCode => Object.hash(sound, start, length);

  @override
  String toString() => 'SoundClip(${sound.id}, $start to $end)';
}
