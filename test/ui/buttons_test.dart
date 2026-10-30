import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/ui/device_colors.dart';
import 'package:shuffle_alarm/ui/key_border.dart';
import 'package:shuffle_alarm/ui/theme.dart';
import 'package:shuffle_alarm/ui/tokens.dart';

// Material buttons look and press like keys because of the component
// themes in lib/ui/theme.dart (D15).

Future<void> _show(WidgetTester tester, Widget button) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: clockRadioTheme(.light),
      home: Scaffold(body: Center(child: button)),
    ),
  );
}

/// The Material that paints the face, edge and outline of [button].
Material _keyOf(WidgetTester tester, Finder button) => tester.widget<Material>(
  find.descendant(of: button, matching: find.byType(Material)).first,
);

KeyBorder _shapeOf(WidgetTester tester, Finder button) =>
    _keyOf(tester, button).shape! as KeyBorder;

Color? _labelColor(WidgetTester tester, String label) =>
    tester.renderObject<RenderParagraph>(find.text(label)).text.style?.color;

ThemeData _theme(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(Scaffold)));

void main() {
  testWidgets('FilledButton is the orange main key', (tester) async {
    await _show(
      tester,
      FilledButton(onPressed: () {}, child: const Text('Stop')),
    );
    final colors = _theme(tester).colorScheme;
    final button = find.byType(FilledButton);

    expect(_keyOf(tester, button).color, colors.primaryContainer);
    expect(
      _shapeOf(tester, button).side.color,
      _theme(tester).extension<DeviceColors>()!.primaryEdge,
    );
    expect(_shapeOf(tester, button).travel, 0);
    expect(_labelColor(tester, 'Stop'), colors.onPrimaryContainer);
  });

  testWidgets('OutlinedButton is a neutral key', (tester) async {
    await _show(
      tester,
      OutlinedButton(onPressed: () {}, child: const Text('Snooze')),
    );
    final theme = _theme(tester);
    final button = find.byType(OutlinedButton);

    expect(
      _keyOf(tester, button).color,
      theme.extension<DeviceColors>()!.keyFace,
    );
    expect(_shapeOf(tester, button).side.color, theme.colorScheme.outline);
    expect(_labelColor(tester, 'Snooze'), theme.colorScheme.onSurface);
  });

  testWidgets('a key and its label sink while pressed', (tester) async {
    await _show(
      tester,
      FilledButton(onPressed: () {}, child: const Text('Stop')),
    );
    final button = find.byType(FilledButton);
    final raisedTop = tester.getRect(find.text('Stop')).top;

    final gesture = await tester.startGesture(tester.getCenter(button));
    await tester.pump(kPressTimeout);

    expect(_shapeOf(tester, button).travel, KeyMetrics.depth);
    expect(tester.getRect(find.text('Stop')).top, raisedTop + KeyMetrics.depth);

    await gesture.up();
    await tester.pump();

    expect(_shapeOf(tester, button).travel, 0);
    expect(tester.getRect(find.text('Stop')).top, raisedTop);
  });

  testWidgets('keys are big enough to hit half-asleep', (tester) async {
    await _show(
      tester,
      Column(
        mainAxisSize: .min,
        children: [
          FilledButton(onPressed: () {}, child: const Text('Stop')),
          IconButton(
            onPressed: () {},
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_rounded),
          ),
        ],
      ),
    );

    expect(
      tester.getSize(find.byType(FilledButton)).height,
      greaterThanOrEqualTo(KeyMetrics.minHeight),
    );
    final icon = tester.getSize(find.byType(IconButton));
    expect(icon.width, greaterThanOrEqualTo(KeyMetrics.iconKey.width));
    expect(icon.height, greaterThanOrEqualTo(KeyMetrics.iconKey.height));
    expect(_shapeOf(tester, find.byType(IconButton)), isA<KeyBorder>());
  });

  testWidgets(
    'keys keep their size on computers',
    variant: TargetPlatformVariant.desktop(),
    (tester) async {
      await _show(
        tester,
        FilledButton(onPressed: () {}, child: const Text('Stop')),
      );

      expect(
        tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(KeyMetrics.minHeight),
      );
    },
  );

  testWidgets('a key with keyboard focus gets a thick focus outline', (
    tester,
  ) async {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await _show(
      tester,
      OutlinedButton(
        focusNode: focus,
        onPressed: () {},
        child: const Text('Snooze'),
      ),
    );

    focus.requestFocus();
    await tester.pump();

    final side = _shapeOf(tester, find.byType(OutlinedButton)).side;
    expect(side.color, _theme(tester).extension<DeviceColors>()!.focus);
    expect(side.width, KeyMetrics.focusOutline);
  });

  test('a key tints faintly under a mouse, and only then', () {
    final style = clockRadioTheme(.light).outlinedButtonTheme.style!;

    expect(style.overlayColor!.resolve({})!.a, 0);
    expect(style.overlayColor!.resolve({WidgetState.hovered})!.a, 0.06);
  });

  testWidgets('a selected key stays pressed in', (tester) async {
    final states = WidgetStatesController({WidgetState.selected});
    addTearDown(states.dispose);
    await _show(
      tester,
      OutlinedButton(
        statesController: states,
        onPressed: () {},
        child: const Text('Mon'),
      ),
    );
    final button = find.byType(OutlinedButton);

    expect(_shapeOf(tester, button).travel, KeyMetrics.depth);
    expect(
      _keyOf(tester, button).color,
      _theme(tester).extension<DeviceColors>()!.keyPressed,
    );
  });

  testWidgets('a disabled key looks pressed in and does not move', (
    tester,
  ) async {
    await _show(
      tester,
      const FilledButton(onPressed: null, child: Text('Stop')),
    );
    final theme = _theme(tester);
    final button = find.byType(FilledButton);

    final gesture = await tester.startGesture(tester.getCenter(button));
    await tester.pump(kPressTimeout);

    expect(
      _keyOf(tester, button).color,
      theme.extension<DeviceColors>()!.keyPressed,
    );
    expect(_shapeOf(tester, button).travel, 0);
    expect(
      _labelColor(tester, 'Stop'),
      theme.colorScheme.onSurface.withValues(alpha: 0.38),
    );
    await gesture.up();
  });

  testWidgets('TextButton is a quiet underlined link, not a key', (
    tester,
  ) async {
    await _show(
      tester,
      TextButton(onPressed: () {}, child: const Text('Try an easier task')),
    );

    expect(
      _keyOf(tester, find.byType(TextButton)).shape,
      isNot(isA<KeyBorder>()),
    );
    expect(
      tester
          .renderObject<RenderParagraph>(find.text('Try an easier task'))
          .text
          .style
          ?.decoration,
      TextDecoration.underline,
    );
  });

  testWidgets('keys show a press by sinking, not with ripples', (tester) async {
    await _show(tester, const SizedBox());
    final theme = _theme(tester);

    for (final style in [
      theme.filledButtonTheme.style,
      theme.outlinedButtonTheme.style,
      theme.iconButtonTheme.style,
      theme.textButtonTheme.style,
    ]) {
      expect(style?.splashFactory, NoSplash.splashFactory);
    }
  });
}
