import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/ui/empty_state.dart';
import 'package:shuffle_alarm/ui/theme.dart';

Future<void> _show(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: dawnTheme(.light),
      home: const Scaffold(
        body: EmptyState(
          icon: Icons.alarm_rounded,
          title: 'No alarms yet',
          message: 'Each one plays a new sound every 30 seconds.',
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the illustration, title and message', (tester) async {
    await _show(tester);

    expect(find.byIcon(Icons.alarm_rounded), findsOneWidget);
    expect(find.text('No alarms yet'), findsOneWidget);
    expect(
      find.text('Each one plays a new sound every 30 seconds.'),
      findsOneWidget,
    );
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
