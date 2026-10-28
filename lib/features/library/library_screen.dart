import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/features/settings/settings_button.dart';

/// The Library tab. A placeholder until the genre library (PLAN.md task 3.7).
class LibraryScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: const [SettingsButton()],
      ),
      body: const Center(child: Text('Sounds and genres will appear here.')),
    );
  }
}
