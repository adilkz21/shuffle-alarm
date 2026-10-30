import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/app.dart';
import 'package:shuffle_alarm/ui/key_tab_bar.dart';
import 'package:shuffle_alarm/ui/tokens.dart';

void main() {
  testWidgets('the tab tray floats and stays narrow on wide screens', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1600, 1000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: ShuffleAlarmApp()));
    await tester.pumpAndSettle();

    final tray = tester.getRect(find.byType(KeyTabBar));
    expect(tray.width, lessThanOrEqualTo(MaxWidths.tabBar));
    expect(tray.center.dx, closeTo(800, 1));
    expect(tray.bottom, lessThan(1000));
  });
}
