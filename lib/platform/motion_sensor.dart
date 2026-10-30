import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shuffle_alarm/platform/native/native_motion_sensor.dart'
    if (dart.library.js_interop) 'package:shuffle_alarm/platform/web/web_motion_sensor.dart';

/// One reading of the motion sensor, in m/s².
typedef MotionReading = ({double x, double y, double z});

/// The device's motion sensor. Features use this and never the platform's own
/// sensor code. A device without a sensor simply reports none, and the "Move"
/// task isn't offered there.
abstract interface class MotionSensor {
  /// Whether the system must ask the user before [readings] can start.
  bool get needsPermission;

  /// Asks the user. Call it straight from a tap, after a short explanation.
  /// Returns whether it was allowed. Never throws.
  Future<bool> requestPermission();

  /// Whether readings really arrive. It takes up to a moment to find out,
  /// because browsers can't tell without trying. Never throws.
  Future<bool> isAvailable();

  /// The readings, while something listens.
  Stream<MotionReading> get readings;
}

/// The sensor of this platform.
final motionSensorProvider = Provider<MotionSensor>(
  (ref) => createMotionSensor(),
);
