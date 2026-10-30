import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/features/settings/settings_button.dart';
import 'package:shuffle_alarm/ui/app_page.dart';
import 'package:shuffle_alarm/ui/empty_state.dart';

/// The Library tab. A placeholder until the genre library, one of the
/// "Questions to test later" in PLAN.md.
class LibraryScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Library',
      subtitle: 'Every sound you can wake up to',
      actions: [SettingsButton()],
      body: EmptyState(
        readout: '--',
        caption: 'Coming soon',
        title: 'Sounds to wake up to',
        message: 'Genres, clips and your own songs will live here.',
      ),
    );
  }
}
