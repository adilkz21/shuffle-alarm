import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/features/settings/settings_button.dart';

/// The Alarms tab. A placeholder until the alarm list (PLAN.md task 2.2).
class AlarmsScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarms'),
        actions: const [SettingsButton()],
      ),
      body: const Center(child: Text('No alarms yet.')),
    );
  }
}
