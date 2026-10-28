# Shuffle Alarm

Cross-platform alarm clock that wakes people with a rotating set of different sounds.
Working title "Shuffle Alarm", package `shuffle_alarm` (rename later if needed).
The roadmap and task checklist live in `PLAN.md`. Run `/next-task` to work on the next task.

## Product rules (never break)
- UI text is English only. Do not add localization.
- One sound plays for at most 30 s. When it ends, the next sound starts immediately.
- The alarm keeps rotating until Stop or Snooze. Total cap: 10 min (setting), then it stops and is logged as "missed".
- Bundled clips are cut to max 29 s, because iOS AlarmKit only accepts alarm sounds shorter than 30 s.
- No copyrighted music. Every bundled audio file needs an entry in `assets/library/manifest.json` (title, artist, license, sourceUrl, attribution).
- Allowed licenses for bundled audio: `original` (made by us), CC0, CC BY 4.0 (credit in the Credits screen), or a license that explicitly allows redistribution inside apps. Never CC BY-NC, CC BY-ND, or "free for videos only" licenses.
- User songs and voice recordings stay on the device. Never upload them anywhere.
- Alarm reliability beats features: any change to scheduling or ringing must pass the alarm test checklist (`PLAN.md` task 4.5) on every affected platform.
- Ask for permissions with a short explanation screen first. No dark patterns.

## Tech stack
- Flutter stable, Dart, Material 3.
- State: flutter_riverpod. Routing: go_router.
- Storage: drift (SQLite, also on web). Simple settings: shared_preferences.
- Audio: audioplayers (supports all 6 platforms). Recording: record. File import: file_picker.
- Alarm scheduling, always behind the `AlarmScheduler` interface:
  - Android: AlarmManager `setAlarmClock` + foreground service + full-screen intent (`alarm` package or own Kotlin plugin, decided in Phase 4).
  - iOS 26+: AlarmKit via `flutter_alarmkit` or `alarm_kit` (decided in Phase 5).
  - Desktop: in-app scheduler + tray icon; the app keeps running in the background.
  - Web: in-tab scheduler, test version only.
- Before adding any package: check pub.dev for platform support, recent releases and license. If it does not cover all 6 platforms, hide it behind an interface with a fallback.

## Architecture
- `lib/core/`: pure Dart, no Flutter imports. Models, `RotationEngine`, clip rules, adaptive weights.
- `lib/data/`: drift database, repositories, library loader for `manifest.json`.
- `lib/platform/`: `AlarmScheduler` and `SoundPlayer` interfaces + `android/`, `ios/`, `desktop/`, `web/` implementations.
- `lib/features/`: `alarms/`, `ringing/`, `library/`, `voice/`, `insights/`, `settings/`.
- `lib/ui/`: the "Dawn" look (colors, fonts) and shared widgets such as `DawnPage` and `EmptyState`. Screens take colors and text styles from the theme, never hard-coded hex values (see `docs/DECISIONS.md` D6).
- `assets/library/<genre>/`: audio clips + `manifest.json`. `tool/`: dev scripts. `test/` mirrors `lib/`.
- Features never call platform code directly, only through the interfaces.

## Commands
- `flutter pub get`
- `flutter run -d chrome` (web test version)
- `dart format .`
- `flutter analyze` (must report 0 issues)
- `flutter test` (one file: `flutter test test/core/rotation_engine_test.dart`)
- `flutter build web --release --base-href /<repo-name>/`
- `dart run tool/check_licenses.dart` (audio license check, from Phase 3)

## Workflow
- Follow `PLAN.md` in order. One task per session; `/clear` between tasks.
- If a task touches 2+ files, propose a short plan first and wait for approval.
- Write tests first for everything in `lib/core/`.
- A task is done only when `flutter analyze` is clean, `flutter test` passes, the task's "Done when" check is met with evidence shown, and its checkbox in `PLAN.md` is ticked.
- Commit after each task: `type(scope): summary`, e.g. `feat(rotation): add shuffle bag`. Then push to `main` (agreed with the user) and check that the CI run is green. CI (`.github/workflows/ci.yml`) checks every push; a green push to `main` publishes the web test version at https://adilkz21.github.io/shuffle-alarm/.
- Never commit secrets, signing keys or user audio.
- If a requirement is unclear or a platform limit blocks it, stop and ask. Record decisions and limits in `docs/DECISIONS.md`.

## Gotchas
- Web: browsers block audio until the user interacts with the page, so alarms need an "Arm alarms" tap. Background tabs are throttled (silent audio does not prevent it), so check the clock on every tick instead of relying on one long timer.
- iOS: AlarmKit fixes the sound when the alarm is scheduled. Sounds must be in the app bundle (.caf/.wav/.aiff, under 30 s); files in Library/Sounds were reported to fall back to the default sound. Rotation = a chain of alarms 30 s apart, each with its own sound; stopping one cancels the rest. There is no public API for alarm loudness, so escalation on iOS = ordering clips from gentle to strong.
- Android: use single-fire `setAlarmClock` alarms and reschedule after each ring, reboot and time-zone change. `USE_EXACT_ALARM` and full-screen intents need Play Console declarations (allowed for alarm apps).
- Desktop: alarms ring only while the computer is awake and the app runs in the tray. Windows and Linux apps must be built on those systems (use GitHub Actions runners).
