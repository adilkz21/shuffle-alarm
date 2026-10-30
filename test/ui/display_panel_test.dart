import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/ui/device_colors.dart';
import 'package:shuffle_alarm/ui/display_panel.dart';
import 'package:shuffle_alarm/ui/theme.dart';

Future<void> _show(WidgetTester tester, Brightness brightness) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: clockRadioTheme(brightness),
      home: const Scaffold(
        body: DisplayPanel(
          child: Column(children: [Text('07:00'), Icon(Icons.alarm_rounded)]),
        ),
      ),
    ),
  );
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('is the dark display in ${brightness.name} mode', (
      tester,
    ) async {
      await _show(tester, brightness);
      final device = DeviceColors.of(tester.element(find.text('07:00')));

      final panel = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(DisplayPanel),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect((panel.decoration as ShapeDecoration).color, device.display);
    });
  }

  testWidgets('text and icons on it are amber', (tester) async {
    await _show(tester, .light);
    final device = DeviceColors.of(tester.element(find.text('07:00')));

    expect(
      tester
          .renderObject<RenderParagraph>(find.text('07:00'))
          .text
          .style
          ?.color,
      device.readout,
    );
    expect(
      IconTheme.of(tester.element(find.byIcon(Icons.alarm_rounded))).color,
      device.readout,
    );
  });
}
