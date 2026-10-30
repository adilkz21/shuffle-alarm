import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shuffle_alarm/platform/native/native_screen_awake.dart'
    if (dart.library.js_interop) 'package:shuffle_alarm/platform/web/web_screen_awake.dart';

/// Keeps the screen on while a ring is on its way: a phone that goes to sleep
/// stops a web page, and the ring would never come. Neither call ever throws;
/// without this ability the screen just follows its usual settings.
abstract interface class ScreenAwake {
  Future<void> keepOn();

  Future<void> allowOff();
}

/// The screen of this platform.
final screenAwakeProvider = Provider<ScreenAwake>((ref) => createScreenAwake());
