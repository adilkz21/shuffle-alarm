import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/app.dart';

Future<void> _startApp(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: ShuffleAlarmApp()));
  await tester.pumpAndSettle();
}

ThemeData _themeOnScreen(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(Scaffold).first));

void main() {
  testWidgets('is called Shuffle Alarm', (tester) async {
    await _startApp(tester);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, 'Shuffle Alarm');
  });

  testWidgets('uses a Material 3 light theme by default', (tester) async {
    await _startApp(tester);

    final theme = _themeOnScreen(tester);
    expect(theme.useMaterial3, isTrue);
    expect(theme.brightness, Brightness.light);
  });

  testWidgets('follows the system dark mode', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await _startApp(tester);

    final theme = _themeOnScreen(tester);
    expect(theme.useMaterial3, isTrue);
    expect(theme.brightness, Brightness.dark);
  });
}
