import 'package:material_ui/material_ui.dart';

/// Colors of the clock radio's parts that `ColorScheme` has no role for:
/// the keys, the tray the tab keys sit in, the lit dot and the display.
/// Read them with `DeviceColors.of(context)`. Why: docs/DECISIONS.md (D15).
/// test/ui/theme_test.dart checks their contrast.
class DeviceColors extends ThemeExtension<DeviceColors> {
  const new({
    required this.keyFace,
    required this.keyPressed,
    required this.primaryEdge,
    required this.tray,
    required this.led,
    required this.focus,
    required this.display,
    required this.displayBorder,
    required this.readout,
    required this.displayLabel,
  });

  /// The face of a neutral key. Its edge and outline are
  /// `ColorScheme.outline`.
  final Color keyFace;

  /// The face of a key that stays down: the open tab, a disabled key.
  final Color keyPressed;

  /// The edge and outline of the orange main key.
  final Color primaryEdge;

  /// The recess the tab keys sit in.
  final Color tray;

  /// The lit dot on the open tab.
  final Color led;

  /// The outline of a key that has keyboard focus.
  final Color focus;

  /// The display window. It stays dark in both modes.
  final Color display;

  /// The rim around the display.
  final Color displayBorder;

  /// Digits and icons on the display.
  final Color readout;

  /// Small captions on the display.
  final Color displayLabel;

  /// The device colors of the theme around [context].
  static DeviceColors of(BuildContext context) =>
      Theme.of(context).extension<DeviceColors>()!;

  @override
  DeviceColors copyWith({
    Color? keyFace,
    Color? keyPressed,
    Color? primaryEdge,
    Color? tray,
    Color? led,
    Color? focus,
    Color? display,
    Color? displayBorder,
    Color? readout,
    Color? displayLabel,
  }) => DeviceColors(
    keyFace: keyFace ?? this.keyFace,
    keyPressed: keyPressed ?? this.keyPressed,
    primaryEdge: primaryEdge ?? this.primaryEdge,
    tray: tray ?? this.tray,
    led: led ?? this.led,
    focus: focus ?? this.focus,
    display: display ?? this.display,
    displayBorder: displayBorder ?? this.displayBorder,
    readout: readout ?? this.readout,
    displayLabel: displayLabel ?? this.displayLabel,
  );

  @override
  DeviceColors lerp(DeviceColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return DeviceColors(
      keyFace: mix(keyFace, other.keyFace),
      keyPressed: mix(keyPressed, other.keyPressed),
      primaryEdge: mix(primaryEdge, other.primaryEdge),
      tray: mix(tray, other.tray),
      led: mix(led, other.led),
      focus: mix(focus, other.focus),
      display: mix(display, other.display),
      displayBorder: mix(displayBorder, other.displayBorder),
      readout: mix(readout, other.readout),
      displayLabel: mix(displayLabel, other.displayLabel),
    );
  }
}

/// Light mode: a warm light-gray clock radio in the morning.
const morningDevice = DeviceColors(
  keyFace: Color(0xFFFBFAF7),
  keyPressed: Color(0xFFE2DED5),
  primaryEdge: Color(0xFFA63F0C),
  tray: Color(0xFFDCD8CF),
  led: Color(0xFFA63F0C),
  focus: Color(0xFF1C1B19),
  display: Color(0xFF1E1D1B),
  displayBorder: Color(0xFF1E1D1B),
  readout: Color(0xFFFFB13B),
  displayLabel: Color(0xFFBFB6A6),
);

/// Dark mode: a graphite clock radio at night.
const nightDevice = DeviceColors(
  keyFace: Color(0xFF2A2826),
  keyPressed: Color(0xFF1F1D1B),
  primaryEdge: Color(0xFF7A2E06),
  tray: Color(0xFF0E0D0C),
  led: Color(0xFFFFB13B),
  focus: Color(0xFFFFB13B),
  display: Color(0xFF0A0A09),
  displayBorder: Color(0xFF3A3732),
  readout: Color(0xFFFFB13B),
  displayLabel: Color(0xFFA89F8F),
);
