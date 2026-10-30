import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/routes.dart';
import 'package:shuffle_alarm/ui/app_page.dart';
import 'package:shuffle_alarm/ui/empty_state.dart';
import 'package:shuffle_alarm/ui/tokens.dart';

/// The Settings page, opened over the tabs. A placeholder for now, with a
/// way to the licenses of the bundled fonts.
class SettingsScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Settings',
      subtitle: 'Tune how you wake up',
      // Opened straight from a URL (say, after a reload on the web) there is
      // no page underneath, so Back goes to Alarms instead.
      leading: context.canPop()
          ? null
          : BackButton(onPressed: () => context.go(AppRoute.alarms.path)),
      body: Column(
        children: [
          const Expanded(
            child: EmptyState(
              readout: '--',
              caption: 'Coming soon',
              title: 'Make it yours',
              message: 'Snooze length, ring time and more will live here.',
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: OutlinedButton(
              onPressed: () => showLicensePage(context: context),
              child: const Text('View licenses'),
            ),
          ),
        ],
      ),
    );
  }
}
