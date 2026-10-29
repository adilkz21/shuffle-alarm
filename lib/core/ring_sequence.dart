import 'dart:math';

import 'package:shuffle_alarm/core/alarm.dart';
import 'package:shuffle_alarm/core/shuffle_bag.dart';
import 'package:shuffle_alarm/core/sound.dart';
import 'package:shuffle_alarm/core/sound_clip.dart';

/// How long a ring lasts at most, unless the user changes it: then it stops
/// and counts as missed.
const defaultRingCap = Duration(minutes: 10);

/// The clips one ring of [alarm] plays, in order: sounds of its genres from
/// [pool], picked by a shuffle bag seeded with [seed] and cut by the clip
/// rule, until together they last at least [cap].
///
/// The last clip plays whole, so the clips can last up to one clip longer
/// than [cap]: the ringing code ends the ring at the cap. Sounds whose clip
/// is shorter than [SoundClip.minLength] are skipped. When [alarm] can play
/// none of the sounds in [pool], the list is empty, and the caller plays a
/// fallback sound instead.
///
/// The same alarm, sounds and seed always give the same clips, whatever the
/// order of [pool]. The list can't be changed.
List<SoundClip> buildRingSequence(
  Alarm alarm,
  Iterable<Sound> pool,
  int seed, {
  Duration cap = defaultRingCap,
}) {
  assert(cap > Duration.zero, 'cap must be positive');
  // Sounds whose clip is too short to recognize never enter the bag, and
  // neither do empty clips from bad data in a release build. So every turn
  // adds at least a second, a pool of only such sounds ends the loop at
  // once, and skipping them can't make a sound play twice in a row.
  final bag = ShuffleBag(
    pool.where(
      (sound) =>
          alarm.playsGenre(sound.genre) &&
          SoundClip.of(sound).length >= SoundClip.minLength,
    ),
    Random(seed),
  );
  final clips = <SoundClip>[];
  var length = Duration.zero;
  while (length < cap) {
    final sound = bag.next();
    if (sound == null) break;
    final clip = SoundClip.of(sound);
    clips.add(clip);
    length += clip.length;
  }
  return List.unmodifiable(clips);
}
