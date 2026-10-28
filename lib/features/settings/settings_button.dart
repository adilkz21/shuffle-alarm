import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/routes.dart';

/// Round app-bar button that opens Settings over the current tab.
class SettingsButton extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IconButton(
      style: IconButton.styleFrom(
        backgroundColor: colors.surfaceContainerHigh,
        foregroundColor: colors.onSurface,
      ),
      icon: const Icon(Icons.settings_rounded),
      tooltip: 'Settings',
      onPressed: () => unawaited(context.push(AppRoute.settings.path)),
    );
  }
}
