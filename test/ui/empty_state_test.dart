import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/ui/display_panel.dart';
import 'package:shuffle_alarm/ui/empty_state.dart';
import 'package:shuffle_alarm/ui/theme.dart';

Future<void> _show(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: clockRadioTheme(.light),
      home: const Scaffold(
        body: EmptyState(
          readout: '--:--',
          caption: 'No alarm set',
          title: 'No alarms yet',
          message: 'Each one plays a new sound every 30 seconds.',
        ),
      ),
    ),
  );
}

Finder _onDisplay(String text) =>
    find.descendant(of: find.byType(DisplayPanel), matching: find.text(text));

void main() {
  testWidgets('shows the display, a title and a message', (tester) async {
    await _show(tester);

    expect(_onDisplay('--:--'), findsOneWidget);
    expect(_onDisplay('NO ALARM SET'), findsOneWidget);
    expect(find.text('No alarms yet'), findsOneWidget);
    expect(
      find.text('Each one plays a new sound every 30 seconds.'),
      findsOneWidget,
    );
  });

  testWidgets('screen readers hear the caption, not the dashes', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _show(tester);

    expect(find.bySemanticsLabel('--:--'), findsNothing);
    expect(find.bySemanticsLabel('No alarm set'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('fits a small phone with large text', (tester) async {
    tester.view
      ..physicalSize = const Size(320, 568)
      ..devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _show(tester);

    // An overflow would be reported here as an exception.
    expect(tester.takeException(), isNull);
    expect(find.text('No alarms yet'), findsOneWidget);
  });
}
