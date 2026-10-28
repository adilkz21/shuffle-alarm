import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/routes.dart';

/// The Settings page, opened over the tabs. A placeholder for now.
class SettingsScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        // Opened straight from a URL (say, after a reload on the web) there is
        // no page underneath, so Back goes to Alarms instead.
        leading: context.canPop()
            ? null
            : BackButton(onPressed: () => context.go(AppRoute.alarms.path)),
      ),
      body: const Center(child: Text('Settings will appear here.')),
    );
  }
}
