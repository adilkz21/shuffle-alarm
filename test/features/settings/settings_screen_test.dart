import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/app.dart';

void main() {
  testWidgets('View licenses opens the licenses page', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ShuffleAlarmApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('View licenses'));
    // The page keeps loading the licenses, so it never settles.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(LicensePage), findsOneWidget);
  });
}
