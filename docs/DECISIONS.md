# Decisions and limits

Decisions made while building Shuffle Alarm, and platform limits we ran into.
Product rules live in [CLAUDE.md](../CLAUDE.md); the roadmap and its decision table live in [PLAN.md](../PLAN.md).

How to add an entry: append it to the right section with the next number (decisions D1, D2…; limits L1, L2…).
Say what was decided, why, and what it affects, in a few lines.
If a later entry replaces an earlier one, mark the old one "Replaced by Dn" instead of deleting it.

## Decisions

### D1 · 2026-10-28 · Project identity and theme (task 0.1)
- **Decision:** org ID `com.adilz`, so the app IDs are `com.adilz.shuffle_alarm` (Android, Linux) and `com.adilz.shuffleAlarm` (iOS, macOS). The display name is "Shuffle Alarm" on every platform. The Material 3 theme comes from one seed color, sunrise orange `#F2994A`, with light and dark versions that follow the system setting.
- **Why:** app IDs are hard to change after a store release. One seed color keeps every screen consistent.
- **Affects:** store setup and signing (Phase 8). The macOS `PRODUCT_NAME` is "Shuffle Alarm" (it is also the window title); this has not been built on a Mac yet.

### D2 · 2026-10-29 · Strict lints with very_good_analysis (task 0.2)
- **Decision:** `very_good_analysis` instead of `flutter_lints`, with the rule set locked to version 11.0.0 in `analysis_options.yaml`. The `public_member_api_docs` rule is off.
- **Why:** about 200 rules plus strict casts, inference and raw types catch bugs before they reach an alarm. Locking the rule-set version means a package update can't break CI with new rules. Doc comments on every public member help published packages, not an app.
- **Affects:** all Dart code; `flutter analyze` must report 0 issues. The rules ask for the newest Dart syntax, such as `const new(...)` constructors and dot shorthands like `.center`. Keep it; don't rewrite it in the old style.

### D3 · 2026-10-29 · Folder rules are checked by a test (task 0.2)
- **Decision:** `test/architecture_test.dart` fails when a file in `lib/core/` imports Flutter or another app layer, or when `lib/features/` imports an implementation from `lib/platform/android|ios|desktop|web/`.
- **Why:** these CLAUDE.md rules are easy to break by accident, and lints can't check them.
- **Affects:** new code in `lib/core/` and `lib/features/`. Empty folders hold a `.gitkeep` file until real files arrive.

### D4 · 2026-10-29 · Navigation with go_router (task 0.3)
- **Decision:** go_router with `StatefulShellRoute.indexedStack`. Alarms, Library and Insights are bottom tabs that keep their own state and history; Settings opens over the tabs. The router lives in a Riverpod provider (`routerProvider` in `lib/router.dart`), and page paths are listed once in `AppRoute` (`lib/routes.dart`). The web build keeps Flutter's default hash URLs (`/#/alarms`). Unknown URLs open Alarms, and Settings opened straight from a URL gets a Back button to Alarms.
- **Why:** each tab keeps its place when you switch. Hash URLs work on GitHub Pages without server rewrites (task 0.4), so reloading a page or opening a shared link never ends in a 404.
- **Affects:** every screen. A new page gets an `AppRoute` value and a route in `lib/router.dart`; a new tab also needs a destination in `lib/app_shell.dart` at the same position as its branch.

### D5 · 2026-10-29 · Material from the material_ui package (task 0.3)
- **Decision:** UI code imports `package:material_ui/material_ui.dart`, not `package:flutter/material.dart`. The switch was made with the official `dart fix --apply --code=migrate_design_widgets`.
- **Why:** Flutter moved Material into its own package. go_router 18 uses it and only recognizes that package's `MaterialApp`; with the old import it would fall back to plain pages without Material transitions. One Material copy also keeps theme lookups consistent.
- **Affects:** all UI code. If a package we add still uses `package:flutter/material.dart`, wrap its widgets in `MaterialUiCompatibilityBridge` (see the material_ui README). The architecture test counts `material_ui` and `cupertino_ui` as Flutter, so `lib/core/` can't import them.

### D6 · 2026-10-29 · The "Dawn" look (task 0.5)
- **Decision:** a hand-picked palette instead of Material's generated one: a violet night sky with a warm apricot sun in dark mode, a soft peach morning in light mode (`lib/ui/theme.dart`). Fraunces (a soft serif) for titles and big numbers, Manrope for everything else, both bundled as variable fonts in `assets/fonts/` with their OFL licenses. Pages build on `DawnPage` (sky background, large title) and `EmptyState` (a sunrise illustration drawn in code). The tab bar floats as a rounded card, at most 480 px wide.
- **Why:** the app should be easy on the eyes and not look like every other Material app. Alarms are set at night and stopped half-asleep, so dark mode is deep and warm instead of blue-white. `test/ui/theme_test.dart` keeps every text color at WCAG AA (4.5:1) on every part of the sky. The fonts are bundled so the app never contacts a font server (local-first, works offline).
- **Affects:** every screen: take colors and text styles from the theme, never hard-coded hex values. The Credits screen (task 3.6) must list Fraunces and Manrope (OFL); `addFontLicenses()` already puts both on Flutter's licenses page.

### D7 · 2026-10-29 · CI and the live web version on GitHub Pages (task 0.4)
- **Decision:** a public repo, `adilkz21/shuffle-alarm`, with one workflow, `.github/workflows/ci.yml`. Every push runs a `dart format` check, `flutter analyze` and `flutter test` on Ubuntu with Flutter 3.47.8 and the lockfile enforced. A push to `main` that passes them builds the web app with the repo name as base href and deploys it to GitHub Pages: https://adilkz21.github.io/shuffle-alarm/. Runs on `main` wait for each other instead of cancelling, so a deploy is never cut off halfway.
- **Why:** Pages and Actions minutes are free for public repos, so no second hosting account or secret is needed. The same Flutter version and locked packages mean CI checks exactly what was tested locally. Only the deploy job gets the Pages permissions, and it runs no third-party code; the third-party `subosito/flutter-action` is pinned to a commit. Hash URLs (D4) need no 404 rewrites on Pages.
- **Affects:** every push: a red check means the site is not updated. Change `FLUTTER_VERSION` in the workflow together with the dev machine's Flutter. The action versions were the newest on 2026-10-29; check them when a run warns about deprecations. Code and commit authors are public.

### D8 · 2026-10-29 · Core models (task 1.1)
- **Decision:** `Alarm`, `Sound`, `RingEvent` and `RingSession` live in `lib/core/` as immutable classes that compare by value; their sets and lists are copied and can't be changed. IDs are strings: a library clip uses its id from `manifest.json`, everything else gets a generated id (AlarmKit uses UUIDs). The time of day is our own `AlarmTime`, because Flutter's `TimeOfDay` can't be used in core. `Intensity` is an enum: gentle, medium, strong = levels 1–3. Empty `repeatDays` means the alarm rings once; empty `genres` means every genre, so an alarm always has sounds to play.
- **Rings:** a `RingEvent` is one sound that played; `timeout` means nobody tapped anything (the clip played to its end, or the ring cap ran out). A `RingSession` is one ring, from the first sound until Stop, Snooze or the cap. The ring after a Snooze is a new session with the same `dueAt`, so the rings of one morning can be grouped (Insights, experiment mode). The outcome comes from the last event: Stop → stopped, Snooze → snoozed, anything else → missed, which includes an app closed while it rang.
- **Why:** value classes keep state and tests simple. Wrong values (hour 24, a clip start past the end) trip an `assert` in tests and debug builds but can't crash a ringing alarm in a release build; data from files and the database is checked where it is loaded. Computing the outcome from the events means the two can never disagree.
- **Affects:** tasks 1.2–1.6 and the database (2.1). Where a sound's file is stored is not part of `Sound` yet; it comes with storage (2.1, 2.6). `lib/core` may use the pure-Dart packages `meta` and `collection`: both are from the Dart team (BSD license) and already came with Flutter, so no package versions changed.

### D9 · 2026-10-29 · The clip rule (task 1.2)
- **Decision:** `SoundClip.of(sound)` in `lib/core/sound_clip.dart` is the part of a sound that plays in one turn: from its `clipStart` to the end of the file, but at most 30 s (`SoundClip.maxLength`), or 29 s for sounds bundled with the app (`SoundClip.maxBundledLength`). It is the only way to make a `SoundClip`, so no clip can break the limits. A clip that starts close to the end of a song is just shorter; its start is not moved back. A bundled file over 29 s is cut, not rejected. The name is not `Clip`, because Flutter has a `Clip` enum that screens would then have to hide.
- **Why:** one sound plays at most 30 s (CLAUDE.md). iOS AlarmKit only accepts alarm sounds shorter than 30 s, and bundled sounds are the ones it can play (5.1 checks user sounds), so they keep a 1-s margin. Cutting instead of rejecting means a packaging mistake can't silence an alarm; `tool/check_licenses.dart` (3.5) is where such files fail. If bad values get past `Sound`'s asserts in a release build, a start outside the file plays from the beginning and a sound without length gives an empty clip. Tests can't build such sounds, because the asserts stop them.
- **Affects:** the ring sequence (1.6) is built from clips and must skip empty ones. The song importer (2.6), voice recorder (2.7) and license check (3.5) should take their limits from these constants. AlarmKit plays the whole bundled file, not a clip of it, so `tool/prepare_audio.sh` (3.3) must still cut the files themselves to 29 s.

## Limits

### L1 · 2026-10-28 · Building on Windows
- iOS and macOS apps can only be built, signed and tested on a Mac with Xcode (Phases 5, 6 and 8).
- On Windows, Flutter plugins need Developer Mode (they use symlinks). Turn it on before Phase 2 adds the first plugins.

### L2 · 2026-10-29 · flutter_riverpod is not tagged for web on pub.dev
- `flutter_riverpod` 3.x depends on `flutter_test`, which imports `dart:io`, so pub.dev marks it "not compatible with Web". The web compiler still builds `dart:io` imports (calling them would fail at runtime), and the app never calls them. Checked in task 0.3: the web release build compiles and runs.
- If a future version really breaks the web, pin the last working version.
