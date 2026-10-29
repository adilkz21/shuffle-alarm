import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/features/settings/settings_button.dart';
import 'package:shuffle_alarm/ui/dawn_page.dart';
import 'package:shuffle_alarm/ui/empty_state.dart';

/// The Insights tab. A placeholder until the morning stats (PLAN.md, Stage 3).
class InsightsScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const DawnPage(
      title: 'Insights',
      subtitle: 'How your mornings went',
      actions: [SettingsButton()],
      body: EmptyState(
        icon: Icons.insights_rounded,
        title: 'Mornings in numbers',
        message: 'After your first alarm, you’ll see how fast you got up.',
      ),
    );
  }
}
