import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/ui/device_colors.dart';
import 'package:shuffle_alarm/ui/fonts.dart';
import 'package:shuffle_alarm/ui/theme.dart';

/// WCAG contrast ratio between two opaque colors, from 1 to 21.
double _contrast(Color a, Color b) {
  final (la, lb) = (a.computeLuminance(), b.computeLuminance());
  final (light, dark) = la > lb ? (la, lb) : (lb, la);
  return (light + 0.05) / (dark + 0.05);
}

/// WCAG AA for normal-size text (1.4.3).
const _readable = 4.5;

/// WCAG AA for the outlines of controls and other parts that aren't text
/// (1.4.11).
const _visible = 3.0;

/// All 15 styles of [text].
List<TextStyle?> _allStyles(TextTheme text) => [
  text.displayLarge,
  text.displayMedium,
  text.displaySmall,
  text.headlineLarge,
  text.headlineMedium,
  text.headlineSmall,
  text.titleLarge,
  text.titleMedium,
  text.titleSmall,
  text.bodyLarge,
  text.bodyMedium,
  text.bodySmall,
  text.labelLarge,
  text.labelMedium,
  text.labelSmall,
];

void main() {
  for (final brightness in Brightness.values) {
    group('${brightness.name} theme', () {
      final theme = clockRadioTheme(brightness);
      final colors = theme.colorScheme;
      final device = theme.extension<DeviceColors>()!;
      final text = theme.textTheme;

      test('is Material 3 in the right mode, with standard density', () {
        expect(theme.useMaterial3, isTrue);
        expect(theme.brightness, brightness);
        expect(colors.brightness, brightness);
        // Desktop density would shrink the keys on computers and the web.
        expect(theme.visualDensity, VisualDensity.standard);
      });

      test('text and muted text are readable on every surface', () {
        final surfaces = {
          'page': colors.surface,
          'lowest container': colors.surfaceContainerLowest,
          'low container': colors.surfaceContainerLow,
          'container': colors.surfaceContainer,
          'high container': colors.surfaceContainerHigh,
          'highest container': colors.surfaceContainerHighest,
          'key': device.keyFace,
          'pressed key': device.keyPressed,
          'tray': device.tray,
        };
        for (final MapEntry(key: place, value: background)
            in surfaces.entries) {
          expect(
            _contrast(colors.onSurface, background),
            greaterThanOrEqualTo(_readable),
            reason: 'text on $place',
          );
          expect(
            _contrast(colors.onSurfaceVariant, background),
            greaterThanOrEqualTo(_readable),
            reason: 'muted text on $place',
          );
        }
      });

      test('text on every colored part is readable', () {
        final pairs = {
          'on primary': (colors.onPrimary, colors.primary),
          'on the orange key': (
            colors.onPrimaryContainer,
            colors.primaryContainer,
          ),
          'on secondary': (colors.onSecondary, colors.secondary),
          'on secondary container': (
            colors.onSecondaryContainer,
            colors.secondaryContainer,
          ),
          'on tertiary': (colors.onTertiary, colors.tertiary),
          'on tertiary container': (
            colors.onTertiaryContainer,
            colors.tertiaryContainer,
          ),
          'on error': (colors.onError, colors.error),
          'on error container': (
            colors.onErrorContainer,
            colors.errorContainer,
          ),
          'accent text on the page': (colors.primary, colors.surface),
          'error text on the page': (colors.error, colors.surface),
          'on inverse surface': (
            colors.onInverseSurface,
            colors.inverseSurface,
          ),
          'inverse accent': (colors.inversePrimary, colors.inverseSurface),
          'display digits': (device.readout, device.display),
          'display captions': (device.displayLabel, device.display),
        };
        for (final MapEntry(key: name, value: (foreground, background))
            in pairs.entries) {
          expect(
            _contrast(foreground, background),
            greaterThanOrEqualTo(_readable),
            reason: name,
          );
        }
      });

      test('keys, the focus ring and the lit dot stand out', () {
        // A control's outline against the colors right next to it.
        for (final (place, background) in [
          ('page', colors.surface),
          ('tray', device.tray),
        ]) {
          expect(
            _contrast(colors.outline, background),
            greaterThanOrEqualTo(_visible),
            reason: 'key outline on the $place',
          );
          expect(
            _contrast(device.focus, background),
            greaterThanOrEqualTo(_visible),
            reason: 'focus ring on the $place',
          );
        }
        for (final (place, face) in [
          ('key', device.keyFace),
          ('pressed key', device.keyPressed),
        ]) {
          expect(
            _contrast(device.focus, face),
            greaterThanOrEqualTo(_visible),
            reason: 'focus ring around a $place',
          );
        }
        // The orange key stands out by its face or by its outline.
        expect([
          _contrast(colors.primaryContainer, colors.surface),
          _contrast(device.primaryEdge, colors.surface),
        ], contains(greaterThanOrEqualTo(_visible)));
        expect(
          _contrast(device.led, device.keyPressed),
          greaterThanOrEqualTo(_visible),
          reason: 'lit dot on the open tab',
        );
      });

      test('digits and key labels use Martian Mono, the rest Onest', () {
        expect(
          [
            text.displayLarge,
            text.displayMedium,
            text.displaySmall,
            text.labelLarge,
            text.labelSmall,
          ].map((style) => style?.fontFamily),
          everyElement(displayFamily),
        );
        expect(
          [
            text.headlineLarge,
            text.headlineMedium,
            text.headlineSmall,
            text.titleLarge,
            text.titleMedium,
            text.titleSmall,
            text.bodyLarge,
            text.bodyMedium,
            text.bodySmall,
            text.labelMedium,
          ].map((style) => style?.fontFamily),
          everyElement(textFamily),
        );
      });

      test('every text style sets the variable-font weight axis', () {
        for (final style in _allStyles(text)) {
          final weight = style!.fontVariations!.singleWhere(
            (variation) => variation.axis == 'wght',
          );
          expect(weight.value, style.fontWeight!.value);
        }
      });

      test('Martian Mono runs at normal width', () {
        // The font's own default is semi-expanded (112.5).
        for (final style in _allStyles(text)) {
          if (style!.fontFamily != displayFamily) continue;
          expect(
            style.fontVariations,
            contains(const FontVariation.width(100)),
          );
        }
      });

      test('no text is smaller than 12 px', () {
        for (final style in _allStyles(text)) {
          expect(style!.fontSize, greaterThanOrEqualTo(12));
        }
      });

      test('page titles are 30 px', () {
        expect(text.headlineMedium?.fontSize, 30);
      });

      test('status bar icons contrast with the page', () {
        final overlay = theme.appBarTheme.systemOverlayStyle!;
        final pageIsLight = brightness == Brightness.light;
        // Android names the icons' brightness, iOS the bar's.
        expect(
          overlay.statusBarIconBrightness,
          pageIsLight ? Brightness.dark : Brightness.light,
        );
        expect(overlay.statusBarBrightness, brightness);
      });
    });
  }
}
