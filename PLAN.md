# Shuffle Alarm — Build Plan

An alarm that plays a different sound every 30 seconds until you get up. One Flutter codebase for web, Android, iOS, macOS, Windows and Linux. The web version comes first, as the test version.

## How to use this plan with Claude Code
1. Make a folder named `shuffle_alarm` and put `CLAUDE.md`, `PLAN.md` and `.claude/skills/next-task/SKILL.md` in it.
2. Open a terminal in that folder and run `claude`.
3. Type `/next-task`. Claude takes the first unchecked task, shows a short plan, builds it, runs the checks, ticks it off and commits.
4. Try the result (from Phase 2 on: the live web site). If something is wrong, describe what you see.
5. Type `/clear`, then `/next-task` again.

Useful extras:
- Run a specific task: `/next-task 2.6`
- At the end of each phase: `Use a subagent to review this phase's changes against PLAN.md. Report only gaps that break a requirement or a "Done when" check.`
- Before a release: `/code-review`

## Before you start
- Flutter (stable channel); `flutter doctor` shows no errors for the platforms you build.
- On your Mac: Xcode 26 or newer (iOS, macOS) and Android Studio (Android).
- A GitHub account and Claude Code.
- For phone tests: an Android phone or emulator, and an iPhone on iOS 26 or newer.

## Decisions
| Topic | Decision |
| --- | --- |
| Stack | Flutter, one codebase for 6 platforms |
| 30-second rule | Each sound plays max 30 s, then the next one starts; it rotates until Stop or Snooze; total cap 10 min (default) |
| Snooze | 5 min (default, changeable) |
| Built-in library | Only free, properly licensed music, grouped by popular genres |
| Research features | Gentle-to-strong escalation, adaptive rotation, voice messages, experiment mode |
| UI language | English only |
| Data | Local-first: no accounts, nothing uploaded (MVP) |
| Build order | Core → Web test version → Library → Android → iOS → Desktop → Research features → Release |

## Why these features
- **Rotation:** the sleeping brain responds more strongly to an unfamiliar voice, and the response fades as the voice becomes familiar (Ameen et al., J Neurosci 2022, 17 people).
- **Gentle start:** alarm sounds rated melodic were linked with less morning grogginess than neutral ones (McFarlane et al., PLOS ONE 2020, 50 people, self-report).
- **Escalation:** a gradually rising alarm was linked with better morning mood in a 14-night home study (Yang, Cera & Pauletto, KTH).
- **Voice messages:** a mother's-voice alarm woke 86–91% of children vs 53% for a tone alarm (Smith et al., J Pediatrics 2018, ages 5–12).
- **Adaptive rotation:** 55.6% of over 3 million tracked nights ended with snooze (Robbins et al., Scientific Reports 2025).
- **Keep Snooze:** 30 min of snoozing did not hurt regular snoozers in a lab study (Sundelin et al., J Sleep Research 2023).
- **Experiment mode:** we found no study comparing "same sound every day" with "a new sound every morning". The app can collect that data.

---

## Phase 0 — Setup
Goal: the empty app builds and the web test version is online.
- [x] 0.1 Create the app in this folder: `flutter create --project-name shuffle_alarm --org com.<yourname> --platforms=android,ios,web,macos,windows,linux .` Material 3 theme, app name "Shuffle Alarm".
- [x] 0.2 Strict lints (`very_good_analysis` or `flutter_lints`), the folder structure from CLAUDE.md, and `docs/DECISIONS.md`.
- [x] 0.3 App shell with go_router and Riverpod: bottom tabs Alarms, Library, Insights, plus a Settings page.
- [ ] 0.4 GitHub repo + GitHub Actions: every push runs `flutter analyze` and `flutter test`; every push to `main` builds the web app and deploys it (GitHub Pages for a public repo; Cloudflare Pages or Firebase Hosting for a private repo).

Done when: CI is green and the app shell opens at the live URL.

## Phase 1 — Core engine (pure Dart, no UI)
Goal: all the "smart" logic exists and is tested before any platform work.
- [ ] 1.1 Models: `Alarm` (id, time, repeat days, label, enabled, genres, gentleStart, experimentGroup), `Sound` (id, title, source: builtin/user/voice, genre, intensity 1–3, duration, clipStart), `RingSession`, `RingEvent` (soundId, startedAt, endedAt, action: stop/snooze/timeout).
- [ ] 1.2 Clip rule: a clip window never exceeds 30 s; bundled clips never exceed 29 s.
- [ ] 1.3 Shuffle bag: no sound repeats until every sound in the pool has played, and never the same sound twice in a row (also across bag refills).
- [ ] 1.4 Escalation: the first sound is intensity 1 (gentle, melodic); each next sound is one level stronger until level 3. A volume value per level (start values 40% → 70% → 100%) for platforms that allow it.
- [ ] 1.5 Adaptive weights: each sound starts at 1.0; the sound playing when the user taps Snooze is multiplied by 0.8; the sound playing when the user taps Stop by 1.1; keep weights between 0.2 and 3.0; weighted pick inside the shuffle bag. (Start values; tune with real data.)
- [ ] 1.6 `buildRingSequence(alarm, pool, weights, seed)`: ordered clips that cover the 10-min cap; same seed gives the same sequence.

Done when: `flutter test test/core` passes, with tests for every rule above, including "no clip over 30 s" and "no sound twice in a row".

## Phase 2 — Web test version
Goal: a working alarm in the browser to try the idea with real people.
- [ ] 2.1 drift database (works on web): alarms, sounds, ring events, weights.
- [ ] 2.2 Alarms screen: list, add/edit (time, repeat days, label, genres), on/off switch, "rings in 7 h 20 min".
- [ ] 2.3 Placeholder library: a script in `tool/` generates 9 original clips (3 genres × 3, synthesized melodies) + `manifest.json` with license `original`. No downloads.
- [ ] 2.4 Web scheduler: "Arm alarms" button (unlocks audio), checks the clock every second, banner "Keep this tab open", screen wake lock if the browser supports it.
- [ ] 2.5 Ringing screen: big clock, current sound title, Stop and Snooze; plays the sequence from 1.6; logs every RingEvent.
- [ ] 2.6 Import own songs (mp3, m4a, wav): pick a 30-s part with a start slider and preview; stored only in the browser.
- [ ] 2.7 Voice messages: record up to 30 s, give it a name ("Mom", "Best friend"), use it in the rotation.
- [ ] 2.8 Insights tab: last 14 mornings with time to Stop, number of snoozes and sounds played.

Done when: in Chrome, an alarm set 1 minute ahead rings after "Arm alarms" with rotating sounds of max 30 s each (on time when the tab is visible, at most about 1 minute late in a background tab); Stop and Snooze are logged; the live site behaves the same.

## Phase 3 — Licensed music library
Goal: a real genre library that is 100% legal.
- [ ] 3.1 Genres v1: Pop, Rock, Hip-Hop, Electronic, Lo-fi, Classical, Jazz, Acoustic, plus Nature sounds.
- [ ] 3.2 `docs/MUSIC_SOURCING.md`: allowed licenses, candidate sources (Freesound with the CC0 filter; Free Music Archive and Incompetech after checking each track's license; Pixabay Music only after reading its Content License) and how to keep proof (license URL + date saved). You choose and download tracks; Claude Code processes them.
- [ ] 3.3 `tool/prepare_audio.sh` (ffmpeg): cut to max 29 s, 0.5 s fade in/out, normalize all clips to the same loudness (e.g. −14 LUFS), export `.mp3` (Android, desktop, web) and `.caf` (iOS, in a format iOS alarm sounds accept).
- [ ] 3.4 `manifest.json` fields: id, title, artist, genre, intensity (1–3), file, durationSec, license, sourceUrl, attribution.
- [ ] 3.5 `tool/check_licenses.dart`: fails if any audio file has no manifest entry, a disallowed license, or is longer than 29 s. Runs in CI.
- [ ] 3.6 Credits screen with all attributions (required for CC BY).
- [ ] 3.7 Library screen: browse by genre, preview, choose genres per alarm.

Done when: every genre has at least 8 clips, the license check passes in CI, and every CC BY track appears in Credits.

## Phase 4 — Android
Goal: alarms ring reliably on a real phone, even when the app is closed.
- [ ] 4.1 Spike: `alarm` package vs a small Kotlin plugin (`setAlarmClock` + foreground service + full-screen intent). Pick one and record why in `docs/DECISIONS.md`.
- [ ] 4.2 `AndroidAlarmScheduler`: single-fire alarms; reschedule after each ring, after reboot, and after a time or time-zone change.
- [ ] 4.3 Ring over the lock screen (full-screen intent); a foreground service plays the rotation with the volume ramp.
- [ ] 4.4 Permission onboarding: notifications, exact alarms, full-screen notifications, battery-optimization tips.
- [ ] 4.5 Alarm test checklist on a real phone: app open / in background / swiped away / phone locked / after reboot / Do Not Disturb on / phone idle overnight.

Done when: every 4.5 check passes on at least one real Android phone.

## Phase 5 — iOS (iOS 26+, AlarmKit)
Goal: alarms ring with the app closed and the phone on silent.
- [ ] 5.1 Spike on a real iPhone: (a) a bundled `.caf` plays as the alarm sound; (b) a chain of alarms 30 s apart with different sounds, where Stop cancels the rest; (c) can a user song or voice recording be the alarm sound?; (d) how many alarms can be scheduled at once? Record results in `docs/DECISIONS.md`.
- [ ] 5.2 `IosAlarmScheduler` with the chosen plugin (`flutter_alarmkit` ships a setup skill for Claude Code); `NSAlarmKitUsageDescription` in Info.plist; a permission screen.
- [ ] 5.3 Rotation through the alarm chain; escalation = clips ordered from gentle to strong.
- [ ] 5.4 If 5.1(c) fails: user songs and voice messages play inside the app after the user opens the alarm; explain this in the UI.
- [ ] 5.5 Run the alarm test checklist from 4.5 on the iPhone.

Done when: the alarm rings with the app closed and the phone on silent, and the rotation works on a real device.

## Phase 6 — Desktop (macOS, Windows, Linux)
Goal: alarms ring while the computer is on.
- [ ] 6.1 Tray icon and "Launch at login"; closing the window keeps the app running in the tray.
- [ ] 6.2 `DesktopAlarmScheduler`: checks the clock every second; the ringing window comes to the front.
- [ ] 6.3 A note in the UI: "Your computer must be awake for alarms to ring."
- [ ] 6.4 Builds: macOS on your Mac; Windows and Linux in GitHub Actions; a manual test on each system.

Done when: the alarm rings with the main window closed on all three systems.

## Phase 7 — Research features, full version
- [ ] 7.1 Escalation settings: gentle start (on by default), max volume.
- [ ] 7.2 Adaptive rotation on by default; "Why this sound?" info; "Reset learning" button.
- [ ] 7.3 Experiment mode: 4 weeks, 2 weeks "same sound" and 2 weeks "rotation" in random order; after Stop, a check-in "How hard was it to get up? (1–5)"; tracks time to Stop, snoozes and missed alarms.
- [ ] 7.4 Export the experiment data as CSV (only when the user taps Export). If friends take part, ask for their consent and collect no names.
- [ ] 7.5 Voice messages from friends: import audio files sent by chat (share sheet or file picker), trim to 30 s.

Done when: a 4-week experiment can run on one device and export a CSV with one row per morning.

## Phase 8 — Release
- [ ] 8.1 App icon, splash screen, store screenshots (English).
- [ ] 8.2 Privacy policy (local-first, no data collected), published on the web site.
- [ ] 8.3 Android: Play Console declarations (exact alarms, full-screen intent); internal testing track.
- [ ] 8.4 iOS: TestFlight (needs a paid Apple Developer account).
- [ ] 8.5 Desktop: signed and notarized macOS build, Windows installer (MSIX), Linux AppImage or Flatpak.
- [ ] 8.6 Final check: `/code-review`, the license check, and the alarm test checklist on every platform.

Done when: testers can install the app on every platform.

## Later (not in the MVP)
- Accounts and cloud sync; sending a voice message straight to a friend's alarm (needs a server and moderation).
- Bedtime reminder (putting off bedtime is linked with worse sleep).
- More genres; smart wake-up in light sleep (needs sleep tracking; check the evidence first).

## Progress log
<!-- Claude Code adds one line per finished task: date, task ID, short note. -->
- 2026-10-28 · 0.1 · Flutter 3.47.8 app for 6 platforms (org `com.adilz`), Material 3 light/dark theme, "Shuffle Alarm" name on every platform; iOS/macOS name changes not checked until a Mac build.
- 2026-10-29 · 0.2 · `very_good_analysis` 11.0.0 (rule set locked, `public_member_api_docs` off), CLAUDE.md folder layout, `test/architecture_test.dart` guarding core/features imports, `docs/DECISIONS.md` started (D1–D3, L1).
- 2026-10-29 · 0.3 · App shell: go_router 18 tabs Alarms/Library/Insights (keep state), Settings on top, hash URLs, unknown URL → Alarms; router in a Riverpod provider; switched to the `material_ui` package (D4, D5, L2). Checked in the web release build.

## References
- Unfamiliar voices in sleep: https://www.ncbi.nlm.nih.gov/pmc/articles/PMC8896625/
- Melodic alarms (PLOS ONE): https://doi.org/10.1371/journal.pone.0215788
- Rising alarm (KTH): https://dael.euracoustics.org/confs/fa2026/data/articles/000156.pdf
- Mother's-voice smoke alarm: https://www.nationwidechildrens.org/newsroom/news-releases/2018/10/smoke-alarm-study
- Snooze study (Scientific Reports): https://news.massgeneralbrigham.org/en/dont-hit-snooze-on-new-research-about-waking-up-each-morning
- Snoozing lab study: https://www.nbcnews.com/health/health-news/ok-hit-snooze-button-according-science-rcna120830
- Bedtime procrastination: https://www.ncbi.nlm.nih.gov/pmc/articles/PMC11059092/
- AlarmKit custom sounds (developer reports): https://developer.apple.com/forums/thread/798140
- flutter_alarmkit: https://pub.dev/packages/flutter_alarmkit
- alarm_kit: https://pub.dev/packages/alarm_kit
- Android full-screen intent limits: https://source.android.com/docs/core/permissions/fsi-limits
- Chrome background tabs: https://developer.chrome.com/blog/background_tabs
- Pixabay terms: https://pixabay.com/service/terms/
- Claude Code best practices: https://code.claude.com/docs/en/best-practices
