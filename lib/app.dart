import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/router.dart';

/// Root widget: app name, the Material 3 light and dark themes, and the
/// router.
class ShuffleAlarmApp extends ConsumerWidget {
  const new({super.key});

  /// Shown in the browser tab and the OS task switcher.
  static const title = 'Shuffle Alarm';

  /// Sunrise orange; Material 3 derives every theme color from it.
  static const _seedColor = Color(0xFFF2994A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: title,
      theme: _theme(.light),
      darkTheme: _theme(.dark),
      routerConfig: ref.watch(routerProvider),
    );
  }

  static ThemeData _theme(Brightness brightness) => ThemeData(
    colorScheme: .fromSeed(seedColor: _seedColor, brightness: brightness),
  );
}
