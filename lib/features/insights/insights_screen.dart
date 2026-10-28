import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/features/settings/settings_button.dart';

/// The Insights tab. A placeholder until the morning stats (PLAN.md task 2.8).
class InsightsScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        actions: const [SettingsButton()],
      ),
      body: const Center(child: Text('Your mornings will show up here.')),
    );
  }
}
