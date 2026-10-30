import 'package:material_ui/material_ui.dart';

// Sizes of the "Clock Radio" look. Screens use these instead of raw
// numbers. Why: docs/DECISIONS.md (D15).

/// Spacing steps, each a multiple of [unit].
abstract final class Spacing {
  static const double unit = 4;
  static const double xs = unit;
  static const double sm = 2 * unit;
  static const double md = 3 * unit;
  static const double lg = 4 * unit;
  static const double xl = 6 * unit;
  static const double xxl = 8 * unit;
}

/// Widest a part of a page gets on big screens.
abstract final class MaxWidths {
  /// A column of text, such as an empty state.
  static const double text = 360;

  /// The tab tray, so it stays within reach on a tablet or a computer.
  static const double tabBar = 480;
}

/// Corner radii.
abstract final class Corners {
  /// Keys.
  static const double key = 16;

  /// The display and the tray the tab keys sit in.
  static const double panel = 24;
}

/// Sizes of the keys.
abstract final class KeyMetrics {
  /// How far a key's edge shows under its face, and how far the key sinks
  /// when it is pressed.
  static const double depth = 5;

  /// The outline around a key.
  static const double outline = 1.5;

  /// The outline of a key that has keyboard focus.
  static const double focusOutline = 3;

  /// Main and neutral keys, edge included.
  static const double minHeight = 60;

  /// The tab keys, edge included.
  static const double tabHeight = 64;

  /// Keys that show only an icon, edge included.
  static const iconKey = Size(52, 56);

  /// Icons on keys.
  static const double icon = 22;

  /// The light on the open tab.
  static const double light = 8;
}
