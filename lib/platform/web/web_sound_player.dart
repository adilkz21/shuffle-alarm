import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:shuffle_alarm/platform/sound_player.dart';
import 'package:web/web.dart' as web;

/// The player of this platform.
SoundPlayer createSoundPlayer() => _WebSoundPlayer();

/// Plays every sound on one audio element. Safari on an iPhone lets an element
/// play without a tap only after it played from one, and audioplayers makes a
/// new element for each sound. Why: docs/DECISIONS.md (D17).
final class _WebSoundPlayer implements SoundPlayer {
  new() {
    _audio.addEventListener('ended', _onEndedJs);
  }

  final _audio = web.HTMLAudioElement();
  final _ended = StreamController<void>.broadcast();
  late final JSFunction _onEndedJs = ((web.Event _) => _ended.add(null)).toJS;
  var _preloaded = false;

  @override
  Future<void> unlock() async {
    try {
      _audio.src = _silence;
      await _audio.play().toDart;
    } on Object catch (_) {
      // A sound that follows at once interrupts this one, which is fine. If
      // the browser refused, playing the first sound will say so.
    }
  }

  @override
  Future<void> preload(Iterable<String> assets) async {
    if (_preloaded) return;
    _preloaded = true;
    await Future.wait(assets.map(_fetch));
  }

  /// Puts the file in the browser's cache, for the audio element to find.
  Future<void> _fetch(String asset) async {
    try {
      await web.window.fetch(_urlOf(asset).toJS).toDart;
    } on Object catch (_) {
      // The audio element will try again when the sound's turn comes.
    }
  }

  @override
  Future<void> play(String asset, {Duration start = Duration.zero}) async {
    _audio
      ..src = _urlOf(asset)
      ..currentTime = start.inMilliseconds / 1000;
    await _audio.play().toDart;
  }

  @override
  Future<void> stop() async => _audio.pause();

  @override
  Stream<void> get onEnded => _ended.stream;

  @override
  Future<void> dispose() async {
    _audio
      ..pause()
      ..removeEventListener('ended', _onEndedJs);
    await _ended.close();
  }
}

String _urlOf(String asset) => ui_web.assetManager.getAssetUrl(asset);

/// A short silent WAV: 16-bit mono at 22,050 Hz, a hundredth of a second.
final String _silence = () {
  const samples = 220;
  const dataSize = samples * 2;
  final bytes = ByteData(44 + dataSize);
  void text(int offset, String value) {
    for (final (i, unit) in value.codeUnits.indexed) {
      bytes.setUint8(offset + i, unit);
    }
  }

  text(0, 'RIFF');
  bytes.setUint32(4, 36 + dataSize, Endian.little);
  text(8, 'WAVEfmt ');
  bytes
    ..setUint32(16, 16, Endian.little)
    ..setUint16(20, 1, Endian.little)
    ..setUint16(22, 1, Endian.little)
    ..setUint32(24, 22050, Endian.little)
    ..setUint32(28, 44100, Endian.little)
    ..setUint16(32, 2, Endian.little)
    ..setUint16(34, 16, Endian.little);
  text(36, 'data');
  bytes.setUint32(40, dataSize, Endian.little);
  return 'data:audio/wav;base64,${base64Encode(bytes.buffer.asUint8List())}';
}();
