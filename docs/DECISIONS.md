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

## Limits

### L1 · 2026-10-28 · Building on Windows
- iOS and macOS apps can only be built, signed and tested on a Mac with Xcode (Phases 5, 6 and 8).
- On Windows, Flutter plugins need Developer Mode (they use symlinks). Turn it on before Phase 2 adds the first plugins.
