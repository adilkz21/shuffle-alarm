import 'package:shuffle_alarm/platform/screen_awake.dart';

/// The screen of this platform. Apps schedule real alarms later, and those
/// don't need the screen on, so this does nothing.
ScreenAwake createScreenAwake() => const _NoScreenAwake();

final class _NoScreenAwake implements ScreenAwake {
  const new();

  @override
  Future<void> keepOn() async {}

  @override
  Future<void> allowOff() async {}
}
