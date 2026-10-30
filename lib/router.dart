import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shuffle_alarm/app_shell.dart';
import 'package:shuffle_alarm/features/alarms/alarms_screen.dart';
import 'package:shuffle_alarm/features/insights/insights_screen.dart';
import 'package:shuffle_alarm/features/library/library_screen.dart';
import 'package:shuffle_alarm/features/ringing/ringing_screen.dart';
import 'package:shuffle_alarm/features/ringing/try_ring.dart';
import 'package:shuffle_alarm/features/settings/settings_screen.dart';
import 'package:shuffle_alarm/routes.dart';

/// The app's router: Alarms, Library and Insights as tabs that each keep
/// their state, and Settings on top of them.
///
/// While a ring goes on, every URL leads to the ringing screen, so going back
/// in a browser can't hide it, and without a ring that screen opens Alarms.
final routerProvider = Provider<GoRouter>((ref) {
  bool isRinging(TryRingState ring) => ring.phase == .ringing;
  final ringing = ValueNotifier(isRinging(ref.read(tryRingProvider)));
  ref
    ..listen(
      tryRingProvider.select(isRinging),
      (_, next) => ringing.value = next,
    )
    ..onDispose(ringing.dispose);
  final router = GoRouter(
    initialLocation: AppRoute.alarms.path,
    refreshListenable: ringing,
    redirect: (_, state) {
      final onRingingPage = state.matchedLocation == AppRoute.ringing.path;
      if (ringing.value && !onRingingPage) return AppRoute.ringing.path;
      if (!ringing.value && onRingingPage) return AppRoute.alarms.path;
      return null;
    },
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
      GoRoute(
        path: AppRoute.ringing.path,
        // A ring shows at once, with no page sliding in.
        pageBuilder: (_, state) =>
            NoTransitionPage(key: state.pageKey, child: const RingingScreen()),
      ),
    ],
    // An unknown or outdated URL opens Alarms instead of an error page.
    onException: (_, _, router) => router.go(AppRoute.alarms.path),
  );
  ref.onDispose(router.dispose);
  return router;
});
