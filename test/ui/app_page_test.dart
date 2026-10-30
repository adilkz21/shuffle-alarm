import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/ui/app_page.dart';
import 'package:shuffle_alarm/ui/theme.dart';

const _page = AppPage(
  title: 'Settings',
  subtitle: 'Tune how you wake up',
  actions: [Icon(Icons.tune_rounded)],
  body: Text('Body'),
);

Future<void> _show(
  WidgetTester tester, {
  Widget page = _page,
  Brightness brightness = .light,
}) async {
  await tester.pumpWidget(
    MaterialApp(theme: clockRadioTheme(brightness), home: page),
  );
}

void main() {
  testWidgets('shows the title as a header, the subtitle and the actions', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _show(tester);

    expect(
      tester.getSemantics(find.text('Settings')),
      isSemantics(isHeader: true),
    );
    expect(find.text('Tune how you wake up'), findsOneWidget);
    expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
    expect(find.text('Body'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('a first page has no back key', (tester) async {
    await _show(tester);

    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('a page opened on top gets a back key', (tester) async {
    await _show(
      tester,
      page: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () =>
                Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => _page)),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Open'), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets('the status bar matches the ${brightness.name} theme', (
      tester,
    ) async {
      await _show(tester, brightness: brightness);

      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
      );
      expect(
        region.value,
        clockRadioTheme(brightness).appBarTheme.systemOverlayStyle,
      );
    });
  }

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
    expect(find.text('Tune how you wake up'), findsOneWidget);
  });
}
