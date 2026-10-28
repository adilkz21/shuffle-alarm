import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/app.dart';

void main() {
  testWidgets('the tab bar floats and stays narrow on wide screens', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1600, 1000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: ShuffleAlarmApp()));
    await tester.pumpAndSettle();

    final bar = tester.getRect(find.byType(NavigationBar));
    expect(bar.width, lessThanOrEqualTo(480));
    expect(bar.center.dx, closeTo(800, 1));
    expect(bar.bottom, lessThan(1000));
  });
}
