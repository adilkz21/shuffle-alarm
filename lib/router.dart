import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shuffle_alarm/app_shell.dart';
import 'package:shuffle_alarm/features/alarms/alarms_screen.dart';
import 'package:shuffle_alarm/features/insights/insights_screen.dart';
import 'package:shuffle_alarm/features/library/library_screen.dart';
import 'package:shuffle_alarm/features/settings/settings_screen.dart';
import 'package:shuffle_alarm/routes.dart';

/// The app's router: Alarms, Library and Insights as tabs that each keep
/// their state, and Settings on top of them.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoute.alarms.path,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        // Same order as the tabs in AppShell.
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.alarms.path,
                builder: (_, _) => const AlarmsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.library.path,
                builder: (_, _) => const LibraryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.insights.path,
                builder: (_, _) => const InsightsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoute.settings.path,
        builder: (_, _) => const SettingsScreen(),
      ),
    ],
    // An unknown or outdated URL opens Alarms instead of an error page.
    onException: (_, _, router) => router.go(AppRoute.alarms.path),
  );
  ref.onDispose(router.dispose);
  return router;
});
