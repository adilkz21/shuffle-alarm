import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shuffle_alarm/app.dart';
import 'package:shuffle_alarm/router.dart';
import 'package:shuffle_alarm/routes.dart';
import 'package:shuffle_alarm/ui/app_page.dart';
import 'package:shuffle_alarm/ui/key_tab_bar.dart';

/// Starts the app and returns its router, for opening URLs.
Future<GoRouter> _startApp(WidgetTester tester) async {
  final container = ProviderContainer.test();
  final router = container.read(routerProvider);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const ShuffleAlarmApp(),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

/// The title of the page on screen.
Finder _title(String text) =>
    find.descendant(of: find.byType(AppPage), matching: find.text(text));

/// A tab in the tab tray.
Finder _tab(String label) =>
    find.descendant(of: find.byType(KeyTabBar), matching: find.text(label));

Future<void> _tapTab(WidgetTester tester, String label) async {
  await tester.tap(_tab(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('starts on Alarms with three tabs', (tester) async {
    await _startApp(tester);

    expect(_title('Alarms'), findsOneWidget);
    expect(find.text('No alarms yet'), findsOneWidget);
    for (final label in ['Alarms', 'Library', 'Insights']) {
      expect(_tab(label), findsOneWidget);
    }
  });

  testWidgets('tapping a tab shows its page', (tester) async {
    await _startApp(tester);

    for (final label in ['Library', 'Insights', 'Alarms']) {
      await _tapTab(tester, label);
      expect(_title(label), findsOneWidget);
    }
  });

  testWidgets('Settings opens over the tabs and goes back', (tester) async {
    await _startApp(tester);
    await _tapTab(tester, 'Insights');

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(_title('Settings'), findsOneWidget);
    expect(find.byType(KeyTabBar), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(_title('Insights'), findsOneWidget);
  });

  testWidgets('a URL opens its tab', (tester) async {
    final router = await _startApp(tester);

    router.go(AppRoute.insights.path);
    await tester.pumpAndSettle();

    expect(_title('Insights'), findsOneWidget);
    final bar = tester.widget<KeyTabBar>(find.byType(KeyTabBar));
    expect(bar.selectedIndex, 2);
  });

  testWidgets('Settings opened by URL goes back to Alarms', (tester) async {
    final router = await _startApp(tester);

    router.go(AppRoute.settings.path);
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(_title('Alarms'), findsOneWidget);
  });

  testWidgets('an unknown URL opens Alarms', (tester) async {
    final router = await _startApp(tester);
    await _tapTab(tester, 'Library');

    router.go('/no-such-page');
    await tester.pumpAndSettle();

    expect(_title('Alarms'), findsOneWidget);
  });
}
