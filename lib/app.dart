import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/router.dart';
import 'package:shuffle_alarm/ui/theme.dart';

/// Root widget: app name, the Dawn light and dark themes, and the router.
class ShuffleAlarmApp extends ConsumerWidget {
  const new({super.key});

  /// Shown in the browser tab and the OS task switcher.
  static const title = 'Shuffle Alarm';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: title,
      theme: dawnTheme(.light),
      darkTheme: dawnTheme(.dark),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
