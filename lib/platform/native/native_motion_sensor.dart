import 'package:shuffle_alarm/platform/motion_sensor.dart';

/// The sensor of this platform: none yet outside the browser, so these apps
/// offer the sound tasks. Why: docs/DECISIONS.md (D17).
MotionSensor createMotionSensor() => const _NoMotionSensor();

final class _NoMotionSensor implements MotionSensor {
  const new();

  @override
  bool get needsPermission => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<bool> isAvailable() async => false;

  @override
  Stream<MotionReading> get readings => const Stream.empty();
}
