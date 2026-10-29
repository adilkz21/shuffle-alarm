# Decisions and findings

Decisions made while building Shuffle Alarm, platform limits we ran into, and what tests with real people taught us.
Product rules live in [CLAUDE.md](../CLAUDE.md); the stages and their questions live in [PLAN.md](../PLAN.md).

How to add an entry:
- A finding from a test with people gets the next F-number and goes at the top of "Findings", newest first. A decision gets the next D-number and goes under its topic; a platform limit gets the next L-number. Next free numbers: F1, D13, L3.
- Say what was decided or seen, why, and what it affects, in a few lines. A decision that follows from a test names its finding ("Why: F2").
- Numbers never change, so links such as "DECISIONS.md (D6)" in code stay valid. If a later entry replaces an earlier one, mark the old one "Replaced by Dn" instead of deleting it.
- Name features, not the numbers of tasks or stages that are not done yet: later stages are planned after each test, so their numbers change.

| Topic | Entries |
| --- | --- |
| [Findings from tests with people](#findings-from-tests-with-people) | none yet |
| [Product](#product) | D12 |
| [Process and planning](#process-and-planning) | D11 |
| [Core engine](#core-engine) | D8, D9, D10 |
| [Code and architecture](#code-and-architecture) | D2, D3, D4, D5 |
| [Look](#look) | D6 |
| [Project, CI and release](#project-ci-and-release) | D1, D7 |
| [Limits](#limits) | L1, L2 |

## Findings from tests with people

None yet: the first findings come from the Stage 2 test. Write each one like this:

```markdown
### F1 · YYYY-MM-DD · Stage 2 · Short title
- **Tested:** who (no names), how many, how long, on what.
- **Saw:** the numbers, and what people did and said.
- **So:** keep, change or drop; the decisions it led to (Dn) and what it means for the next stage.
```

## Product

### D12 · 2026-10-29 · Wake-up tasks alone, and squads that stop together
- **Decision:** Stop no longer just stops. Alone, it opens a short wake-up task built on our sounds ("Which sound is playing?", "Catch the change") or on movement ("Move" for 30 s), and the sounds keep rotating until it is done. In a squad of 2–6 people who share an alarm, each phone shows a 3-digit code that changes every 30 s, and your alarm stops only when you have entered every squad mate's code, so whoever is up first wakes the others: in the same room, or by calling a friend. The rotation of sounds stays the base. Alone comes first (Stage 2), squads next (Stage 3); both are first tested awake, in the daytime. Solo alarms keep Snooze; squad alarms have none, because a snoozed phone would hide its code from the others.
- **Why:** the goal is that people get up, and a plain Stop button makes it easy to fall back asleep. Tasks such as math, typing, steps, photos and barcodes are already common in other alarm apps, and group alarms that ring everyone and show who is up arrived in numbers in 2025–26, all with accounts and servers. We found none that stops only when everyone is up, and none that works without a server. Squad codes come from a secret the squad shares when members join (like two-factor codes), so squads need no accounts and nothing leaves the devices. A 30-s burst of exercise on waking made people feel less sleepy in a small study (15 people); we found no study on math tasks, so our tests decide which tasks stay.
- **Safety:** a task or a squad never locks anyone in. The ring cap still ends the ring (logged as missed), holding Stop for 5 s is an emergency stop that always works and is logged, and every task has an easier fallback for people who can't hear or move well. In a squad, "Stop alone" opens a harder solo task after 3 minutes, and the squad recap shows it.
- **Affects:** CLAUDE.md product rules; the stages in `PLAN.md`; new code in `lib/core/` (wake-up tasks, squad codes; the codes need HMAC from a pure-Dart package such as `crypto`, checked when it is added); feature folders `tasks/` and `squads/`; a `MotionSensor` interface, since computers have no motion sensor. AlarmKit always shows a system Stop button, so on an iPhone the chain of alarms must keep ringing until the task or the codes are done in the app; the iPhone spike checks this. Squad mates can't see live who is up: that would need a server.

## Process and planning

### D11 · 2026-10-29 · Stages by question, with a test on real people after each
- **Decision:** `PLAN.md` is a list of short stages instead of fixed phases by platform. Each stage asks one question about how people wake up, builds only what it takes to answer it (1–2 weeks), and ends with a test on real people with a "pass if" check. The results become findings (F-numbers) in this file, and they decide the next stage. The current stage is planned in detail and the next one roughly; the rest of the old plan became "Questions to test later", with its notes kept. Phase 0 became Stage 0 and tasks 1.1–1.3 Stage 1, with the same numbers. The ring sequence (old 1.6) is now task 2.1; escalation (old 1.4) and adaptive weights (old 1.5) became questions. The first test with people (Stage 2) is a short, awake try of the rotation; the first test on real mornings comes after it (Stage 3). This file now starts with the findings and groups decisions by topic; no number changed.
- **Why:** the old plan fixed every feature in advance. Building in the order of open questions lets testers decide which features the app gets, so it grows its own way, and an idea that doesn't work is dropped after a week instead of after a phase.
- **Affects:** every next step. `/next-task` works on the current stage and doesn't start the next one before its test; CLAUDE.md's workflow says the same. The alarm test checklist is now its own section in `PLAN.md`. Testers are friends who agree to take part; we collect no names, and results leave a device only when a tester copies or exports them. In this file, future work is named by feature or stage, not by task number.
- **Stages 2 and 3 replaced by D12:** they now test wake-up tasks alone and squads; the way of working above still holds.

## Core engine

### D8 · 2026-10-29 · Core models (task 1.1)
- **Decision:** `Alarm`, `Sound`, `RingEvent` and `RingSession` live in `lib/core/` as immutable classes that compare by value; their sets and lists are copied and can't be changed. IDs are strings: a library clip uses its id from `manifest.json`, everything else gets a generated id (AlarmKit uses UUIDs). The time of day is our own `AlarmTime`, because Flutter's `TimeOfDay` can't be used in core. `Intensity` is an enum: gentle, medium, strong = levels 1–3. Empty `repeatDays` means the alarm rings once; empty `genres` means every genre, so an alarm always has sounds to play.
- **Rings:** a `RingEvent` is one sound that played; `timeout` means nobody tapped anything (the clip played to its end, or the ring cap ran out). A `RingSession` is one ring, from the first sound until Stop, Snooze or the cap. The ring after a Snooze is a new session with the same `dueAt`, so the rings of one morning can be grouped (Insights, experiment mode). The outcome comes from the last event: Stop → stopped, Snooze → snoozed, anything else → missed, which includes an app closed while it rang.
- **Why:** value classes keep state and tests simple. Wrong values (hour 24, a clip start past the end) trip an `assert` in tests and debug builds but can't crash a ringing alarm in a release build; data from files and the database is checked where it is loaded. Computing the outcome from the events means the two can never disagree.
- **Affects:** the clip rule (1.2), the shuffle bag (1.3), the ring sequence and the database. Where a sound's file is stored is not part of `Sound` yet; it comes with the manifest loader, storage and the song importer. `lib/core` may use the pure-Dart packages `meta` and `collection`: both are from the Dart team (BSD license) and already came with Flutter, so no package versions changed.

### D9 · 2026-10-29 · The clip rule (task 1.2)
- **Decision:** `SoundClip.of(sound)` in `lib/core/sound_clip.dart` is the part of a sound that plays in one turn: from its `clipStart` to the end of the file, but at most 30 s (`SoundClip.maxLength`), or 29 s for sounds bundled with the app (`SoundClip.maxBundledLength`). It is the only way to make a `SoundClip`, so no clip can break the limits. A clip that starts close to the end of a song is just shorter; its start is not moved back. A bundled file over 29 s is cut, not rejected. The name is not `Clip`, because Flutter has a `Clip` enum that screens would then have to hide.
- **Why:** one sound plays at most 30 s (CLAUDE.md). iOS AlarmKit only accepts alarm sounds shorter than 30 s, and bundled sounds are the ones it can play (the iPhone spike checks user sounds), so they keep a 1-s margin. Cutting instead of rejecting means a packaging mistake can't silence an alarm; `tool/check_licenses.dart` is where such files fail. If bad values get past `Sound`'s asserts in a release build, a start outside the file plays from the beginning and a sound without length gives an empty clip. Tests can't build such sounds, because the asserts stop them.
- **Affects:** the ring sequence is built from clips and must skip empty ones. The song importer, voice recorder and license check should take their limits from these constants. AlarmKit plays the whole bundled file, not a clip of it, so `tool/prepare_audio.sh` must still cut the files themselves to 29 s.

### D10 · 2026-10-29 · The shuffle bag (task 1.3)
- **Decision:** `ShuffleBag` in `lib/core/shuffle_bag.dart` hands out the sounds of a ring one at a time, like cards from a bag: every sound in its pool plays once per round, in random order, then the bag refills. A new round never starts with the sound that ended the last one, so no sound plays twice in a row. All randomness comes from the `Random` the caller passes in, and the bag sorts its sounds by id, so the same sounds and the same seed always give the same sequence, whatever order they come in. Each sound is picked when it is needed instead of shuffling a whole round ahead, so escalation can ask for a certain intensity and adaptive weights can weight the pick.
- **Edge cases:** an empty pool gives no sound (`next()` returns null), and the caller decides what plays instead. A pool of one sound plays it every turn: twice in a row can't be avoided there, and the alarm must keep ringing. A pool of two takes turns (A B A B…). Sounds with the same id count as one sound, and the first one is kept, because the id names a sound in ring events, weights and the manifest.
- **Why:** rotation only helps if every sound gets its turn before any comes back. "No repeat" counts per round: a stricter rule (a sound comes back only after every other sound has played since its last turn) would force every round into the same order, so at the seam between two rounds a sound can come back after just one other sound.
- **Affects:** the ring sequence and, later, escalation and adaptive weights. `buildRingSequence` makes the bag with `Random(seed)` and must cope with `next()` returning null. Dart's `Random` may change its numbers between SDK releases, so a sequence that must be replayed after an app update should be stored as sound ids, not as a seed.

## Code and architecture

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

## Look

### D6 · 2026-10-29 · The "Dawn" look (task 0.5)
- **Decision:** a hand-picked palette instead of Material's generated one: a violet night sky with a warm apricot sun in dark mode, a soft peach morning in light mode (`lib/ui/theme.dart`). Fraunces (a soft serif) for titles and big numbers, Manrope for everything else, both bundled as variable fonts in `assets/fonts/` with their OFL licenses. Pages build on `DawnPage` (sky background, large title) and `EmptyState` (a sunrise illustration drawn in code). The tab bar floats as a rounded card, at most 480 px wide.
- **Why:** the app should be easy on the eyes and not look like every other Material app. Alarms are set at night and stopped half-asleep, so dark mode is deep and warm instead of blue-white. `test/ui/theme_test.dart` keeps every text color at WCAG AA (4.5:1) on every part of the sky. The fonts are bundled so the app never contacts a font server (local-first, works offline).
- **Affects:** every screen: take colors and text styles from the theme, never hard-coded hex values. The Credits screen (it comes with the music library) must list Fraunces and Manrope (OFL); `addFontLicenses()` already puts both on Flutter's licenses page.

## Project, CI and release

### D1 · 2026-10-28 · Project identity and theme (task 0.1)
- **Decision:** org ID `com.adilz`, so the app IDs are `com.adilz.shuffle_alarm` (Android, Linux) and `com.adilz.shuffleAlarm` (iOS, macOS). The display name is "Shuffle Alarm" on every platform. The Material 3 theme comes from one seed color, sunrise orange `#F2994A`, with light and dark versions that follow the system setting.
- **Why:** app IDs are hard to change after a store release. One seed color keeps every screen consistent.
- **Affects:** store setup and signing for the public beta. The macOS `PRODUCT_NAME` is "Shuffle Alarm" (it is also the window title); this has not been built on a Mac yet.
- **Theme replaced by D6:** the app no longer uses a seed color; the identity part still holds.

### D7 · 2026-10-29 · CI and the live web version on GitHub Pages (task 0.4)
- **Decision:** a public repo, `adilkz21/shuffle-alarm`, with one workflow, `.github/workflows/ci.yml`. Every push runs a `dart format` check, `flutter analyze` and `flutter test` on Ubuntu with Flutter 3.47.8 and the lockfile enforced. A push to `main` that passes them builds the web app with the repo name as base href and deploys it to GitHub Pages: https://adilkz21.github.io/shuffle-alarm/. Runs on `main` wait for each other instead of cancelling, so a deploy is never cut off halfway.
- **Why:** Pages and Actions minutes are free for public repos, so no second hosting account or secret is needed. The same Flutter version and locked packages mean CI checks exactly what was tested locally. Only the deploy job gets the Pages permissions, and it runs no third-party code; the third-party `subosito/flutter-action` is pinned to a commit. Hash URLs (D4) need no 404 rewrites on Pages.
- **Affects:** every push: a red check means the site is not updated. Change `FLUTTER_VERSION` in the workflow together with the dev machine's Flutter. The action versions were the newest on 2026-10-29; check them when a run warns about deprecations. Code and commit authors are public.

## Limits

### L1 · 2026-10-28 · Building on Windows
- iOS and macOS apps can only be built, signed and tested on a Mac with Xcode (the iPhone and computer questions, and the public beta).
- On Windows, Flutter plugins need Developer Mode (they use symlinks). Turn it on before Stage 2 adds the first plugins.

### L2 · 2026-10-29 · flutter_riverpod is not tagged for web on pub.dev
- `flutter_riverpod` 3.x depends on `flutter_test`, which imports `dart:io`, so pub.dev marks it "not compatible with Web". The web compiler still builds `dart:io` imports (calling them would fail at runtime), and the app never calls them. Checked in task 0.3: the web release build compiles and runs.
- If a future version really breaks the web, pin the last working version.
