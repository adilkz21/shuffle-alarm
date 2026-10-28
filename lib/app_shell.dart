import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Bottom tabs around the Alarms, Library and Insights pages, in the same
/// order as the branches in `router.dart`.
class AppShell extends StatelessWidget {
  const new({required this.navigationShell, super.key});

  /// The tab pages; each keeps its state while another tab is open.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Pages run under the floating tab bar; their bottom inset keeps
      // content clear of it.
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: _FloatingTabBar(navigationShell: navigationShell),
    );
  }
}

/// The tab bar as a rounded card floating above the bottom edge, never
/// wider than a phone so it stays easy to reach on big screens.
class _FloatingTabBar extends StatelessWidget {
  const new({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final shape = BorderRadius.circular(28);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Align(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceContainerHigh,
              borderRadius: shape,
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: 0.6),
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(
                    alpha: theme.brightness == Brightness.dark ? 0.4 : 0.1,
                  ),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: shape,
              child: NavigationBar(
                selectedIndex: navigationShell.currentIndex,
                // Tapping the open tab again returns to its first page.
                onDestinationSelected: (index) => navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                ),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.alarm_rounded),
                    label: 'Alarms',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.library_music_rounded),
                    label: 'Library',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.insights_rounded),
                    label: 'Insights',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
