import 'dart:math';

import 'package:collection/collection.dart';
import 'package:shuffle_alarm/core/sound.dart';

/// Picks the sounds of a ring like cards from a bag: every sound in the
/// pool plays once, in random order, before the bag is refilled. A new
/// round never starts with the sound that ended the last one, so no sound
/// plays twice in a row.
final class ShuffleBag {
  /// A bag of the sounds in [pool], in an order the given [Random] decides.
  ///
  /// Sounds with the same id count as one sound, and the first one is kept.
  /// The bag sorts the sounds by id, so the same sounds and the same seed
  /// always give the same sequence, whatever order the pool comes in.
  new(Iterable<Sound> pool, this._random) : _sounds = _uniqueById(pool);

  /// The sounds of the pool, each id once, in id order.
  final List<Sound> _sounds;

  final Random _random;

  /// The sounds of this round that haven't played yet.
  final _left = <Sound>[];

  /// The sound [next] gave last; null before the first one.
  Sound? _last;

  /// The sound to play next, or null when the pool is empty.
  Sound? next() {
    if (_sounds.isEmpty) return null;
    if (_left.isEmpty) _left.addAll(_sounds);
    // Only a new round still holds the sound that played last. It must not
    // open the round, unless it is the only sound in the pool: then it
    // plays again, because the alarm must keep ringing.
    final choices = [
      for (final sound in _left)
        if (sound.id != _last?.id) sound,
    ];
    final sound = choices.isEmpty
        ? _left.first
        : choices[_random.nextInt(choices.length)];
    _left.remove(sound);
    _last = sound;
    return sound;
  }
}

/// [pool] with each id once, keeping the first sound with that id, sorted
/// by id.
List<Sound> _uniqueById(Iterable<Sound> pool) {
  final byId = <String, Sound>{};
  for (final sound in pool) {
    byId.putIfAbsent(sound.id, () => sound);
  }
  return byId.values.sortedBy((sound) => sound.id);
}
