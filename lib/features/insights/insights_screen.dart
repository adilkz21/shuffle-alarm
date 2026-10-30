import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/features/settings/settings_button.dart';
import 'package:shuffle_alarm/ui/app_page.dart';
import 'package:shuffle_alarm/ui/empty_state.dart';

/// The Insights tab. A placeholder until the morning stats (PLAN.md, Stage 3).
class InsightsScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Insights',
      subtitle: 'How your mornings went',
      actions: [SettingsButton()],
      body: EmptyState(
        // How long getting up took, once there is a morning to show.
        readout: '-:--',
        caption: 'No mornings yet',
        title: 'Mornings in numbers',
        message: 'After your first alarm, you’ll see how fast you got up.',
      ),
    );
  }
}
