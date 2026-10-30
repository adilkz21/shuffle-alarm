import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/routes.dart';

/// The key in the page header that opens Settings over the current tab.
class SettingsButton extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings_rounded),
      tooltip: 'Settings',
      onPressed: () => unawaited(context.push(AppRoute.settings.path)),
    );
  }
}
