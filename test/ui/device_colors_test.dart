import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/ui/device_colors.dart';

/// Every color of [device], in declaration order.
List<Color> _colorsOf(DeviceColors device) => [
  device.keyFace,
  device.keyPressed,
  device.primaryEdge,
  device.tray,
  device.led,
  device.focus,
  device.display,
  device.displayBorder,
  device.readout,
  device.displayLabel,
];

void main() {
  test('lerp blends each color with its own counterpart', () {
    final halfway = morningDevice.lerp(nightDevice, 0.5);

    expect(_colorsOf(halfway), [
      for (final (i, color) in _colorsOf(morningDevice).indexed)
        Color.lerp(color, _colorsOf(nightDevice)[i], 0.5),
    ]);
    expect(_colorsOf(morningDevice.lerp(nightDevice, 1)), [
      ..._colorsOf(nightDevice),
    ]);
  });

  test('lerp with nothing keeps the colors', () {
    expect(_colorsOf(nightDevice.lerp(null, 0.5)), _colorsOf(nightDevice));
  });

  test('copyWith without values keeps every color', () {
    expect(_colorsOf(nightDevice.copyWith()), _colorsOf(nightDevice));
  });

  test('copyWith changes only the given color', () {
    const red = Color(0xFFFF0000);

    final copy = morningDevice.copyWith(led: red);

    expect(copy.led, red);
    expect(_colorsOf(copy)..removeAt(4), _colorsOf(morningDevice)..removeAt(4));
  });
}
