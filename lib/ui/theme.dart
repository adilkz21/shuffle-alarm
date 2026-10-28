import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/ui/fonts.dart';

// The "Dawn" look: a violet night sky with a warm sunrise in dark mode, a
// soft peach morning in light mode. Why: docs/DECISIONS.md (D6).
// test/ui/theme_test.dart keeps every text color at WCAG AA contrast.

/// Dark mode: the night sky.
const nightColors = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFFFB077),
  onPrimary: Color(0xFF452000),
  primaryContainer: Color(0xFF6B3A12),
  onPrimaryContainer: Color(0xFFFFDCC5),
  secondary: Color(0xFFF4A6C8),
  onSecondary: Color(0xFF4A1230),
  secondaryContainer: Color(0xFF4D2A44),
  onSecondaryContainer: Color(0xFFFFD8E8),
  tertiary: Color(0xFFA9B9FF),
  onTertiary: Color(0xFF15255F),
  tertiaryContainer: Color(0xFF2C3B78),
  onTertiaryContainer: Color(0xFFDDE1FF),
  error: Color(0xFFFFB4AB),
  onError: Color(0xFF690005),
  errorContainer: Color(0xFF93000A),
  onErrorContainer: Color(0xFFFFDAD6),
  surface: Color(0xFF120F1F),
  onSurface: Color(0xFFF4EEE8),
  onSurfaceVariant: Color(0xFFBDB3CB),
  surfaceDim: Color(0xFF120F1F),
  surfaceBright: Color(0xFF383052),
  surfaceContainerLowest: Color(0xFF0B0916),
  surfaceContainerLow: Color(0xFF18142A),
  surfaceContainer: Color(0xFF1D1830),
  surfaceContainerHigh: Color(0xFF241E3A),
  surfaceContainerHighest: Color(0xFF2D2645),
  outline: Color(0xFF8C82A0),
  outlineVariant: Color(0xFF3A3350),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFFF4EEE8),
  onInverseSurface: Color(0xFF2A2438),
  inversePrimary: Color(0xFF9A4A12),
  surfaceTint: Color(0xFFFFB077),
);

/// Light mode: a warm morning.
const morningColors = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFFA8461A),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFFFDBC8),
  onPrimaryContainer: Color(0xFF3A1500),
  secondary: Color(0xFF9C3E66),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFFFD8E6),
  onSecondaryContainer: Color(0xFF3E0021),
  tertiary: Color(0xFF4A5BA8),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFDDE1FF),
  onTertiaryContainer: Color(0xFF00174F),
  error: Color(0xFFBA1A1A),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFFDAD6),
  onErrorContainer: Color(0xFF410002),
  surface: Color(0xFFFFF8F1),
  onSurface: Color(0xFF2B1F2E),
  onSurfaceVariant: Color(0xFF5E4F61),
  surfaceDim: Color(0xFFE8D5C6),
  surfaceBright: Color(0xFFFFF8F1),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFFFF2E7),
  surfaceContainer: Color(0xFFFCEBDD),
  surfaceContainerHigh: Color(0xFFF7E3D3),
  surfaceContainerHighest: Color(0xFFF1DBC8),
  outline: Color(0xFF8E7D8E),
  outlineVariant: Color(0xFFE2CFC2),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFF3A2F3C),
  onInverseSurface: Color(0xFFFBEFF0),
  inversePrimary: Color(0xFFFFB68D),
  surfaceTint: Color(0xFFA8461A),
);

/// The page background: a gradient from top to bottom, and a sunrise glow
/// that rises from the bottom edge.
class Sky {
  const new({required this.gradient, required this.glow});

  /// Colors from the top of the page to the bottom.
  final List<Color> gradient;

  /// Translucent glow, strongest at the bottom center.
  final Color glow;
}

const _nightSky = Sky(
  gradient: [Color(0xFF0E0B1A), Color(0xFF1A1430), Color(0xFF2A1A38)],
  glow: Color(0x38FF9A5C),
);

const _morningSky = Sky(
  gradient: [Color(0xFFFFFAF4), Color(0xFFFFF1E6), Color(0xFFFFE2CF)],
  glow: Color(0x59FFB27A),
);

/// The sky behind every page in [brightness] mode.
Sky skyFor(Brightness brightness) =>
    brightness == Brightness.dark ? _nightSky : _morningSky;

/// The sun in illustrations, from its bright edge to its warm center. It
/// looks the same in both modes.
const sunColors = [Color(0xFFFFC58F), Color(0xFFFF8A4C)];

/// Icons and text drawn on the sun.
const onSun = Color(0xFF452000);

/// The app theme in [brightness] mode.
ThemeData dawnTheme(Brightness brightness) {
  final colors = brightness == Brightness.dark ? nightColors : morningColors;
  final base = ThemeData(colorScheme: colors, fontFamily: sansFamily);
  // ThemeData only adds font sizes when a widget reads the theme, so styles
  // handed straight to components (titles, tab labels) need them here.
  final text = _dawnText(Typography.englishLike2021.merge(base.textTheme));
  return base.copyWith(
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 20,
      toolbarHeight: 88,
      actionsPadding: const EdgeInsets.only(right: 12),
      foregroundColor: colors.onSurface,
      titleTextStyle: text.headlineMedium,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      indicatorShape: const StadiumBorder(),
      indicatorColor: colors.primary.withValues(alpha: 0.16),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 24,
          color: states.contains(WidgetState.selected)
              ? colors.primary
              : colors.onSurfaceVariant,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? _withWeight(
                text.labelMedium!,
                FontWeight.w700,
              ).copyWith(color: colors.primary)
            : text.labelMedium!.copyWith(color: colors.onSurfaceVariant),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: colors.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );
}

/// Fraunces for display, headline and large title styles; Manrope for the
/// rest. Each style also sets the variable fonts' weight axis, because some
/// platforms ignore `fontWeight` for variable fonts.
TextTheme _dawnText(TextTheme base) {
  TextStyle? serif(TextStyle? style, FontWeight weight) {
    if (style == null) return null;
    return _withWeight(style, weight).copyWith(
      fontFamily: serifFamily,
      fontVariations: [
        FontVariation.weight(weight.value.toDouble()),
        FontVariation.opticalSize(style.fontSize ?? 24),
        // Rounder letter ends: the friendly side of Fraunces.
        const FontVariation('SOFT', 100),
      ],
    );
  }

  TextStyle? sans(TextStyle? style) =>
      style == null ? null : _withWeight(style, style.fontWeight);

  return base.copyWith(
    displayLarge: serif(base.displayLarge, FontWeight.w500),
    displayMedium: serif(base.displayMedium, FontWeight.w500),
    displaySmall: serif(base.displaySmall, FontWeight.w500),
    headlineLarge: serif(base.headlineLarge, FontWeight.w600),
    headlineMedium: serif(base.headlineMedium, FontWeight.w600),
    headlineSmall: serif(base.headlineSmall, FontWeight.w600),
    titleLarge: serif(base.titleLarge, FontWeight.w600),
    titleMedium: sans(base.titleMedium),
    titleSmall: sans(base.titleSmall),
    bodyLarge: sans(base.bodyLarge),
    bodyMedium: sans(base.bodyMedium),
    bodySmall: sans(base.bodySmall),
    labelLarge: sans(base.labelLarge),
    labelMedium: sans(base.labelMedium),
    labelSmall: sans(base.labelSmall),
  );
}

/// [style] at [weight], with the matching variable-font weight axis.
TextStyle _withWeight(TextStyle style, FontWeight? weight) {
  final w = weight ?? FontWeight.w400;
  return style.copyWith(
    fontWeight: w,
    fontVariations: [FontVariation.weight(w.value.toDouble())],
  );
}
