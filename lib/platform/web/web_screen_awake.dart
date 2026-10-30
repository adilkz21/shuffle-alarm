import 'dart:async';
import 'dart:js_interop';

import 'package:shuffle_alarm/platform/screen_awake.dart';
import 'package:web/web.dart' as web;

/// The screen of this platform.
ScreenAwake createScreenAwake() => _WebScreenAwake();

/// Uses the browser's Screen Wake Lock. The browser lets go of it when the tab
/// is hidden, so it is asked for again when the tab comes back.
final class _WebScreenAwake implements ScreenAwake {
  new() {
    web.document.addEventListener('visibilitychange', _onVisibilityJs);
  }

  late final JSFunction _onVisibilityJs = ((web.Event _) {
    if (_wanted && web.document.visibilityState == 'visible') {
      unawaited(_request());
    }
  }).toJS;

  var _wanted = false;
  web.WakeLockSentinel? _lock;

  @override
  Future<void> keepOn() async {
    _wanted = true;
    await _request();
  }

  @override
  Future<void> allowOff() async {
    _wanted = false;
    try {
      await _lock?.release().toDart;
    } on Object catch (_) {
      // Already released.
    }
    _lock = null;
  }

  Future<void> _request() async {
    try {
      _lock = await web.window.navigator.wakeLock.request('screen').toDart;
    } on Object catch (_) {
      // Not supported, or refused; the screen follows its usual settings.
    }
  }
}
