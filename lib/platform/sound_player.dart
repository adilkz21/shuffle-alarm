import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shuffle_alarm/platform/native/native_sound_player.dart'
    if (dart.library.js_interop) 'package:shuffle_alarm/platform/web/web_sound_player.dart';

/// Plays the sounds of a ring, one at a time. Features use this and never the
/// platform's own audio code.
abstract interface class SoundPlayer {
  /// Lets sounds play later without a tap. Call it straight from a tap,
  /// before any `await`: browsers only allow sound after one. Never throws.
  Future<void> unlock();

  /// Gets the [assets] ready, so a ring doesn't wait for them. Never throws.
  Future<void> preload(Iterable<String> assets);

  /// Plays the asset with the key [asset] from [start], in place of whatever
  /// is playing. Completes when the sound really started; throws when it
  /// can't play.
  Future<void> play(String asset, {Duration start = Duration.zero});

  /// Silences the player. Never throws.
  Future<void> stop();

  /// Fires when a sound reached the end of its file.
  Stream<void> get onEnded;

  Future<void> dispose();
}

/// The player of this platform.
final soundPlayerProvider = Provider<SoundPlayer>((ref) {
  final player = createSoundPlayer();
  ref.onDispose(player.dispose);
  return player;
});
