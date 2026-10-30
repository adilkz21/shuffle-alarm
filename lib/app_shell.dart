import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shuffle_alarm/ui/key_tab_bar.dart';
import 'package:shuffle_alarm/ui/tokens.dart';

/// The tab tray under the Alarms, Library and Insights pages, with the
/// tabs in the same order as the branches in `router.dart`.
class AppShell extends StatelessWidget {
  const new({required this.navigationShell, super.key});

  /// The tab pages; each keeps its state while another tab is open.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Pages run under the floating tray; their bottom inset keeps
      // content clear of it.
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(
          left: Spacing.lg,
          right: Spacing.lg,
          bottom: Spacing.md,
        ),
        // Never wider than a phone, so it stays easy to reach on big
        // screens.
        child: Align(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: MaxWidths.tabBar),
            child: KeyTabBar(
              selectedIndex: navigationShell.currentIndex,
              // Tapping the open tab again returns to its first page.
              onSelected: (index) => navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              ),
              tabs: const [
                KeyTab(icon: Icons.alarm_rounded, label: 'Alarms'),
                KeyTab(icon: Icons.library_music_rounded, label: 'Library'),
                KeyTab(icon: Icons.insights_rounded, label: 'Insights'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
