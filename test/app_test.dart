import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shuffle_alarm/app.dart';

void main() {
  testWidgets('shows the app name', (tester) async {
    await tester.pumpWidget(const ShuffleAlarmApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, 'Shuffle Alarm');
    expect(find.text('Shuffle Alarm'), findsOneWidget);
  });

  testWidgets('uses a Material 3 light theme by default', (tester) async {
    await tester.pumpWidget(const ShuffleAlarmApp());

    final theme = Theme.of(tester.element(find.byType(Scaffold)));
    expect(theme.useMaterial3, isTrue);
    expect(theme.brightness, Brightness.light);
  });

  testWidgets('follows the system dark mode', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(const ShuffleAlarmApp());

    final theme = Theme.of(tester.element(find.byType(Scaffold)));
    expect(theme.useMaterial3, isTrue);
    expect(theme.brightness, Brightness.dark);
  });
}
