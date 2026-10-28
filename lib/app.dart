import 'package:flutter/material.dart';

/// Root widget: app name and the Material 3 light and dark themes.
class ShuffleAlarmApp extends StatelessWidget {
  const ShuffleAlarmApp({super.key});

  /// Shown in the app bar, the browser tab and the OS task switcher.
  static const title = 'Shuffle Alarm';

  /// Sunrise orange; Material 3 derives every theme color from it.
  static const _seedColor = Color(0xFFF2994A);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: _theme(.light),
      darkTheme: _theme(.dark),
      home: const _HomePage(),
    );
  }

  static ThemeData _theme(Brightness brightness) => ThemeData(
    colorScheme: .fromSeed(seedColor: _seedColor, brightness: brightness),
  );
}

/// Placeholder until the app shell with tabs (PLAN.md task 0.3).
class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text(ShuffleAlarmApp.title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: .min,
            children: [
              Icon(Icons.alarm, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'A different sound every 30 seconds until you get up.',
                style: theme.textTheme.titleMedium,
                textAlign: .center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
