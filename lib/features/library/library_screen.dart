import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/features/settings/settings_button.dart';
import 'package:shuffle_alarm/ui/dawn_page.dart';
import 'package:shuffle_alarm/ui/empty_state.dart';

/// The Library tab. A placeholder until the genre library (PLAN.md task 3.7).
class LibraryScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const DawnPage(
      title: 'Library',
      subtitle: 'Every sound you can wake up to',
      actions: [SettingsButton()],
      body: EmptyState(
        icon: Icons.library_music_rounded,
        title: 'Sounds to wake up to',
        message: 'Genres, clips and your own songs will live here.',
      ),
    );
  }
}
