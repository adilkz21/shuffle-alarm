import 'package:audioplayers/audioplayers.dart';
import 'package:shuffle_alarm/platform/sound_player.dart';

/// The player of this platform.
SoundPlayer createSoundPlayer() => _NativeSoundPlayer();

/// Plays sounds with audioplayers, which adds its own `assets/` to the key.
final class _NativeSoundPlayer implements SoundPlayer {
  final _player = AudioPlayer();

  @override
  Future<void> unlock() async {}

  @override
  Future<void> preload(Iterable<String> assets) async {}

  @override
  Future<void> play(String asset, {Duration start = Duration.zero}) => _player
      .play(AssetSource(asset.replaceFirst('assets/', '')), position: start);

  @override
  Future<void> stop() async {
    try {
      await _player.stop();
    } on Object catch (_) {
      // Nothing was playing.
    }
  }

  @override
  Stream<void> get onEnded => _player.onPlayerComplete;

  @override
  Future<void> dispose() => _player.dispose();
}
