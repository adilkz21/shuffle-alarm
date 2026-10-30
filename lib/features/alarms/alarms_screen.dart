import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/features/settings/settings_button.dart';
import 'package:shuffle_alarm/ui/app_page.dart';
import 'package:shuffle_alarm/ui/empty_state.dart';

/// The Alarms tab. A placeholder until the alarm list (PLAN.md, Stage 3).
class AlarmsScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Alarms',
      subtitle: 'Wake up to something new',
      actions: [SettingsButton()],
      body: EmptyState(
        readout: '--:--',
        caption: 'No alarm set',
        title: 'No alarms yet',
        message: 'Each one plays a new sound every 30 seconds until you’re up.',
      ),
    );
  }
}
