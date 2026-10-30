import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/ui/device_colors.dart';
import 'package:shuffle_alarm/ui/key_border.dart';
import 'package:shuffle_alarm/ui/key_tab_bar.dart';
import 'package:shuffle_alarm/ui/theme.dart';
import 'package:shuffle_alarm/ui/tokens.dart';

const _tabs = [
  KeyTab(icon: Icons.alarm_rounded, label: 'Alarms'),
  KeyTab(icon: Icons.library_music_rounded, label: 'Library'),
  KeyTab(icon: Icons.insights_rounded, label: 'Insights'),
];

/// Shows the bar with tab [open] open and returns the tabs tapped.
Future<List<int>> _show(WidgetTester tester, {int open = 0}) async {
  final taps = <int>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: clockRadioTheme(.light),
      home: Scaffold(
        bottomNavigationBar: KeyTabBar(
          tabs: _tabs,
          selectedIndex: open,
          onSelected: taps.add,
        ),
      ),
    ),
  );
  return taps;
}

/// The key of the tab labeled [label].
Finder _tab(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(OutlinedButton));

Material _keyOf(WidgetTester tester, String label) => tester.widget<Material>(
  find.descendant(of: _tab(label), matching: find.byType(Material)).first,
);

void main() {
  testWidgets('shows every tab as a key in the tray', (tester) async {
    await _show(tester);

    for (final tab in _tabs) {
      expect(_tab(tab.label), findsOneWidget);
    }
    final tray = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(KeyTabBar),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final device = DeviceColors.of(tester.element(find.byType(KeyTabBar)));
    expect((tray.decoration as BoxDecoration).color, device.tray);
  });

  testWidgets('the open tab stays pressed in, with its light on', (
    tester,
  ) async {
    await _show(tester, open: 1);
    final device = DeviceColors.of(tester.element(find.byType(KeyTabBar)));

    final open = _keyOf(tester, 'Library');
    expect((open.shape! as KeyBorder).travel, KeyMetrics.depth);
    expect(open.color, device.keyPressed);
    expect(
      find.descendant(
        of: _tab('Library'),
        matching: find.byKey(KeyTabBar.lightKey),
      ),
      findsOneWidget,
    );

    final closed = _keyOf(tester, 'Alarms');
    expect((closed.shape! as KeyBorder).travel, 0);
    expect(closed.color, device.keyFace);
    expect(
      find.descendant(
        of: _tab('Alarms'),
        matching: find.byKey(KeyTabBar.lightKey),
      ),
      findsNothing,
    );
  });

  testWidgets('screen readers hear which tab is open', (tester) async {
    final semantics = tester.ensureSemantics();
    await _show(tester, open: 1);

    expect(
      tester.getSemantics(_tab('Library')),
      isSemantics(label: 'Library', isButton: true, isSelected: true),
    );
    expect(
      tester.getSemantics(_tab('Alarms')),
      isSemantics(label: 'Alarms', isButton: true, isSelected: false),
    );
    semantics.dispose();
  });

  testWidgets('tapping a tab says which one', (tester) async {
    final taps = await _show(tester);

    await tester.tap(find.text('Insights'));

    expect(taps, [2]);
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
    expect(find.text('Insights'), findsOneWidget);
  });
}
