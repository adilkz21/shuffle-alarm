import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/ui/fonts.dart';
import 'package:shuffle_alarm/ui/theme.dart';

/// WCAG contrast ratio between two opaque colors, from 1 to 21.
double _contrast(Color a, Color b) {
  final (la, lb) = (a.computeLuminance(), b.computeLuminance());
  final (light, dark) = la > lb ? (la, lb) : (lb, la);
  return (light + 0.05) / (dark + 0.05);
}

/// WCAG AA for normal-size text.
const _readable = 4.5;

void main() {
  for (final brightness in Brightness.values) {
    group('${brightness.name} theme', () {
      final theme = dawnTheme(brightness);
      final colors = theme.colorScheme;
      final sky = skyFor(brightness);

      // Everywhere text can sit: the sky from top to bottom, the spot where
      // the sunrise glow is strongest, and the raised surfaces.
      final backgrounds = {
        for (final (i, color) in sky.gradient.indexed) 'sky stop $i': color,
        'sunrise glow': Color.alphaBlend(sky.glow, sky.gradient.last),
        'surface': colors.surface,
        'tab bar': colors.surfaceContainerHigh,
      };

      test('is Material 3 in the right mode', () {
        expect(theme.useMaterial3, isTrue);
        expect(theme.brightness, brightness);
      });

      test('text and muted text are readable everywhere', () {
        for (final MapEntry(key: place, value: background)
            in backgrounds.entries) {
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

      test('accent colors are readable', () {
        expect(
          _contrast(colors.onPrimary, colors.primary),
          greaterThanOrEqualTo(_readable),
        );
        expect(
          _contrast(colors.onPrimaryContainer, colors.primaryContainer),
          greaterThanOrEqualTo(_readable),
        );
        // The selected tab's label.
        expect(
          _contrast(colors.primary, colors.surfaceContainerHigh),
          greaterThanOrEqualTo(_readable),
        );
        for (final sun in sunColors) {
          expect(_contrast(onSun, sun), greaterThanOrEqualTo(_readable));
        }
      });

      test('titles use Fraunces and everything else Manrope', () {
        final text = theme.textTheme;
        expect(
          [
            text.displayLarge,
            text.headlineMedium,
            text.headlineSmall,
            text.titleLarge,
          ].map((style) => style?.fontFamily),
          everyElement(serifFamily),
        );
        expect(
          [
            text.titleMedium,
            text.bodyLarge,
            text.bodyMedium,
            text.labelMedium,
          ].map((style) => style?.fontFamily),
          everyElement(sansFamily),
        );
      });

      test('page titles are large and tab labels small', () {
        expect(theme.appBarTheme.titleTextStyle?.fontSize, 28);
        final label = theme.navigationBarTheme.labelTextStyle?.resolve({});
        expect(label?.fontSize, 12);
      });

      test('every text style sets the variable-font weight axis', () {
        final text = theme.textTheme;
        for (final style in [
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
        ]) {
          final weight = style!.fontVariations!.singleWhere(
            (variation) => variation.axis == 'wght',
          );
          expect(weight.value, style.fontWeight!.value);
        }
      });
    });
  }
}
