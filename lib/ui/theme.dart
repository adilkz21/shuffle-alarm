import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/ui/device_colors.dart';
import 'package:shuffle_alarm/ui/fonts.dart';
import 'package:shuffle_alarm/ui/key_border.dart';
import 'package:shuffle_alarm/ui/tokens.dart';

// The "Clock Radio" look: a warm light-gray clock radio in the morning, a
// graphite one at night, with a dark display and keys that sink when
// pressed. Why: docs/DECISIONS.md (D15).
// test/ui/theme_test.dart keeps every text color at WCAG AA contrast.

/// Light mode: the clock radio in the morning. `primaryContainer` is the
/// orange main key and `tertiary` the display.
const morningColors = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFFA63F0C),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFF2611D),
  onPrimaryContainer: Color(0xFF1C1B19),
  secondary: Color(0xFF5E5A52),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFDCD8CF),
  onSecondaryContainer: Color(0xFF1C1B19),
  tertiary: Color(0xFF1E1D1B),
  onTertiary: Color(0xFFFFB13B),
  tertiaryContainer: Color(0xFF1E1D1B),
  onTertiaryContainer: Color(0xFFFFB13B),
  error: Color(0xFFB3261E),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFF9DEDC),
  onErrorContainer: Color(0xFF410E0B),
  surface: Color(0xFFECE9E2),
  onSurface: Color(0xFF1C1B19),
  onSurfaceVariant: Color(0xFF5E5A52),
  surfaceDim: Color(0xFFDCD8CF),
  surfaceBright: Color(0xFFF6F4EF),
  surfaceContainerLowest: Color(0xFFFBFAF7),
  surfaceContainerLow: Color(0xFFF5F2EC),
  surfaceContainer: Color(0xFFF0EDE6),
  surfaceContainerHigh: Color(0xFFE2DED5),
  surfaceContainerHighest: Color(0xFFDCD8CF),
  outline: Color(0xFF776F63),
  outlineVariant: Color(0xFFCFC9BD),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFF1E1D1B),
  onInverseSurface: Color(0xFFEDE6DA),
  inversePrimary: Color(0xFFFFB13B),
  surfaceTint: Color(0xFFA63F0C),
);

/// Dark mode: the clock radio at night.
const nightColors = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFFFB13B),
  onPrimary: Color(0xFF2B1700),
  primaryContainer: Color(0xFFE8641C),
  onPrimaryContainer: Color(0xFF140A04),
  secondary: Color(0xFFA39C90),
  onSecondary: Color(0xFF1C1B19),
  secondaryContainer: Color(0xFF2A2826),
  onSecondaryContainer: Color(0xFFEDE6DA),
  tertiary: Color(0xFF0A0A09),
  onTertiary: Color(0xFFFFB13B),
  tertiaryContainer: Color(0xFF0A0A09),
  onTertiaryContainer: Color(0xFFFFB13B),
  error: Color(0xFFF2B8B5),
  onError: Color(0xFF601410),
  errorContainer: Color(0xFF8C1D18),
  onErrorContainer: Color(0xFFF9DEDC),
  surface: Color(0xFF151413),
  onSurface: Color(0xFFEDE6DA),
  onSurfaceVariant: Color(0xFFA39C90),
  surfaceDim: Color(0xFF0E0D0C),
  surfaceBright: Color(0xFF34312E),
  surfaceContainerLowest: Color(0xFF0E0D0C),
  surfaceContainerLow: Color(0xFF1A1918),
  surfaceContainer: Color(0xFF1F1D1B),
  surfaceContainerHigh: Color(0xFF2A2826),
  surfaceContainerHighest: Color(0xFF34312E),
  outline: Color(0xFF6E685F),
  outlineVariant: Color(0xFF3A3732),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFFEDE6DA),
  onInverseSurface: Color(0xFF1C1B19),
  inversePrimary: Color(0xFFA63F0C),
  surfaceTint: Color(0xFFFFB13B),
);

/// The app theme in [brightness] mode.
ThemeData clockRadioTheme(Brightness brightness) {
  // Status bar icons: dark on the light body, light on the dark one.
  final (colors, device, statusIcons) = switch (brightness) {
    Brightness.light => (morningColors, morningDevice, Brightness.dark),
    Brightness.dark => (nightColors, nightDevice, Brightness.light),
  };
  final base = ThemeData(
    colorScheme: colors,
    fontFamily: textFamily,
    // Desktop density would shrink the keys on computers and the web.
    visualDensity: VisualDensity.standard,
  );
  // ThemeData only adds font sizes when a widget reads the theme, so styles
  // handed straight to components (button labels) need them here.
  final text = _clockRadioText(
    Typography.englishLike2021.merge(base.textTheme),
  );
  ButtonStyle neutralKey({
    EdgeInsets padding = _keyPadding,
    Size minimumSize = _keySize,
  }) => _keyStyle(
    face: device.keyFace,
    label: colors.onSurface,
    outline: colors.outline,
    colors: colors,
    device: device,
    textStyle: text.labelLarge,
    padding: padding,
    minimumSize: minimumSize,
  );
  return base.copyWith(
    textTheme: text,
    extensions: [device],
    appBarTheme: AppBarTheme(
      backgroundColor: colors.surface,
      foregroundColor: colors.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: text.titleLarge,
      // AppPage puts this on the status bar too.
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: statusIcons,
        statusBarBrightness: brightness,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: _keyStyle(
        face: colors.primaryContainer,
        label: colors.onPrimaryContainer,
        outline: device.primaryEdge,
        colors: colors,
        device: device,
        textStyle: text.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(style: neutralKey()),
    iconButtonTheme: IconButtonThemeData(
      style: neutralKey(
        padding: EdgeInsets.zero,
        minimumSize: KeyMetrics.iconKey,
      ).copyWith(iconSize: const WidgetStatePropertyAll(KeyMetrics.icon)),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colors.onSurface,
        textStyle: text.titleSmall?.copyWith(
          decoration: TextDecoration.underline,
        ),
        minimumSize: const Size.square(48),
        splashFactory: NoSplash.splashFactory,
      ),
    ),
  );
}

const _keyPadding = EdgeInsets.symmetric(
  horizontal: Spacing.xl,
  vertical: Spacing.md,
);

const _keySize = Size(88, KeyMetrics.minHeight);

/// A key: [face] with [label] on it, and an edge and outline in [outline].
/// It sinks while it is pressed and stays pressed in while it is selected
/// (the open tab). It gets a thick outline in the focus color when it has
/// keyboard focus, and looks pressed in and faded when it is disabled.
ButtonStyle _keyStyle({
  required Color face,
  required Color label,
  required Color outline,
  required ColorScheme colors,
  required DeviceColors device,
  required TextStyle? textStyle,
  EdgeInsets padding = _keyPadding,
  Size minimumSize = _keySize,
}) {
  const depth = KeyMetrics.depth;
  final faded = colors.onSurface.withValues(alpha: 0.38);
  bool disabled(Set<WidgetState> states) =>
      states.contains(WidgetState.disabled);
  bool selected(Set<WidgetState> states) =>
      states.contains(WidgetState.selected);
  bool sunk(Set<WidgetState> states) =>
      (states.contains(WidgetState.pressed) || selected(states)) &&
      !disabled(states);
  Color foreground(Set<WidgetState> states) => disabled(states) ? faded : label;

  return ButtonStyle(
    textStyle: WidgetStatePropertyAll(textStyle),
    backgroundColor: WidgetStateProperty.resolveWith(
      (states) =>
          disabled(states) || selected(states) ? device.keyPressed : face,
    ),
    foregroundColor: WidgetStateProperty.resolveWith(foreground),
    iconColor: WidgetStateProperty.resolveWith(foreground),
    overlayColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.hovered)
          ? colors.onSurface.withValues(alpha: 0.06)
          : Colors.transparent,
    ),
    shadowColor: const WidgetStatePropertyAll(Colors.transparent),
    surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
    elevation: const WidgetStatePropertyAll(0),
    minimumSize: WidgetStatePropertyAll(minimumSize),
    // The content sits on the face, so it goes down with it.
    padding: WidgetStateProperty.resolveWith(
      (states) =>
          padding +
          (sunk(states)
              ? const EdgeInsets.only(top: depth)
              : const EdgeInsets.only(bottom: depth)),
    ),
    side: WidgetStateProperty.resolveWith((states) {
      if (disabled(states)) {
        return BorderSide(
          color: outline.withValues(alpha: 0.38),
          width: KeyMetrics.outline,
        );
      }
      if (states.contains(WidgetState.focused)) {
        return BorderSide(color: device.focus, width: KeyMetrics.focusOutline);
      }
      return BorderSide(color: outline, width: KeyMetrics.outline);
    }),
    shape: WidgetStateProperty.resolveWith(
      (states) => KeyBorder(travel: sunk(states) ? depth : 0),
    ),
    // A key shows its press by sinking, at once, as a real key does.
    splashFactory: NoSplash.splashFactory,
    animationDuration: Duration.zero,
  );
}

/// The type scale. Martian Mono, at normal width, for digits, key labels
/// and display captions; Onest for the rest. Each style also sets the
/// weight axis, because some platforms ignore `fontWeight` for variable
/// fonts.
TextTheme _clockRadioText(TextTheme base) {
  TextStyle? mono(
    TextStyle? style,
    double size,
    FontWeight weight, {
    double? height,
    double letterSpacing = 0,
  }) => style?.copyWith(
    fontFamily: displayFamily,
    fontSize: size,
    fontWeight: weight,
    height: height,
    letterSpacing: letterSpacing,
    fontVariations: [
      FontVariation.weight(weight.value.toDouble()),
      // The font's own default is semi-expanded.
      const FontVariation.width(100),
    ],
  );

  TextStyle? sans(
    TextStyle? style,
    double size,
    FontWeight weight, {
    double? height,
  }) => style?.copyWith(
    fontFamily: textFamily,
    fontSize: size,
    fontWeight: weight,
    height: height,
    letterSpacing: 0,
    fontVariations: [FontVariation.weight(weight.value.toDouble())],
  );

  return base.copyWith(
    displayLarge: mono(base.displayLarge, 72, .w700, height: 1),
    displayMedium: mono(base.displayMedium, 56, .w700, height: 1),
    displaySmall: mono(base.displaySmall, 40, .w700, height: 1),
    headlineLarge: sans(base.headlineLarge, 32, .w700, height: 1.15),
    headlineMedium: sans(base.headlineMedium, 30, .w700, height: 1.15),
    headlineSmall: sans(base.headlineSmall, 24, .w700, height: 1.2),
    titleLarge: sans(base.titleLarge, 22, .w700, height: 1.25),
    titleMedium: sans(base.titleMedium, 17, .w600, height: 1.35),
    titleSmall: sans(base.titleSmall, 15, .w600, height: 1.35),
    bodyLarge: sans(base.bodyLarge, 17, .w400, height: 1.45),
    bodyMedium: sans(base.bodyMedium, 15, .w400, height: 1.45),
    bodySmall: sans(base.bodySmall, 13, .w400, height: 1.45),
    labelLarge: mono(base.labelLarge, 15, .w700, letterSpacing: 1),
    labelMedium: sans(base.labelMedium, 13, .w600),
    labelSmall: mono(base.labelSmall, 12, .w600, letterSpacing: 1.5),
  );
}
