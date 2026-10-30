import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:shuffle_alarm/platform/motion_sensor.dart';
import 'package:web/web.dart' as web;

/// The sensor of this platform.
MotionSensor createMotionSensor() => _WebMotionSensor();

/// Reads the browser's `devicemotion` event, which Chrome and Safari on phones
/// both have; sensors_plus uses an API Safari lacks. Why: docs/DECISIONS.md
/// (D17).
final class _WebMotionSensor implements MotionSensor {
  /// How long to wait for a first reading. Computers without a sensor send
  /// one empty event or none.
  static const _firstReadingWait = Duration(milliseconds: 1500);

  late final _readings = StreamController<MotionReading>.broadcast(
    onListen: () => web.window.addEventListener('devicemotion', _onMotionJs),
    onCancel: () => web.window.removeEventListener('devicemotion', _onMotionJs),
  );
  late final JSFunction _onMotionJs = _onMotion.toJS;
  var _allowed = false;

  void _onMotion(web.DeviceMotionEvent event) {
    final reading = event.accelerationIncludingGravity;
    final (x, y, z) = (reading?.x, reading?.y, reading?.z);
    if (x == null || y == null || z == null) return;
    _readings.add((x: x, y: y, z: z));
  }

  /// `DeviceMotionEvent`, if the browser has it.
  JSObject? get _motionEvent =>
      globalContext.getProperty<JSObject?>('DeviceMotionEvent'.toJS);

  @override
  bool get needsPermission =>
      !_allowed &&
      (_motionEvent?.hasProperty('requestPermission'.toJS).toDart ?? false);

  @override
  Future<bool> requestPermission() async {
    try {
      final answer = await _motionEvent!
          .callMethod<JSPromise<JSString>>('requestPermission'.toJS)
          .toDart;
      return _allowed = answer.toDart == 'granted';
    } on Object catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isAvailable() async {
    try {
      await _readings.stream.first.timeout(_firstReadingWait);
      return true;
    } on Object catch (_) {
      return false;
    }
  }

  @override
  Stream<MotionReading> get readings => _readings.stream;
}
