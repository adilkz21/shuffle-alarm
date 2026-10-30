# Shuffle Alarm — Plan

An alarm that won't let you just tap Stop and fall back asleep. A different sound plays every 30 seconds; alone, you stop it with a short wake-up task; in a squad of friends, it stops only when everyone is up. One Flutter codebase for web, Android, iOS, macOS, Windows and Linux; the web version is the test version.

## How we work
We build in short stages. Each stage asks one question about how people wake up, builds only what it takes to answer it (1–2 weeks), and ends with a test on real people. What the test shows is written down in `docs/DECISIONS.md` as findings, and the findings decide the next stage. The current stage is planned in detail and the next one roughly; everything else is a list of questions to test later, not a promise. Why: `docs/DECISIONS.md` (D11).

Every stage has:
- **Question:** what we want to learn.
- **Build:** tasks numbered `<stage>.<n>`, one Claude Code session each.
- **Ready when:** the technical check before testers get it.
- **Test with people:** who, how many, how long, and what we ask or measure.
- **Pass if:** the result that lets us go on. **If not:** what we change first.

With Claude Code:
1. Type `/next-task`. Claude takes the first unchecked task of the current stage, shows a short plan, builds it, runs the checks, ticks it off and commits. `/next-task 2.3` runs a specific task.
2. Try the result on the live web site. If something is wrong, describe what you see. Then `/clear` and `/next-task` again.
3. When every task of the stage is ticked and its "Ready when" check passes, run the test with people.
4. Tell Claude what the testers did and said, for example `Stage 2 test results: …`. Claude writes the findings into `docs/DECISIONS.md`, marks the stage done and plans the next stage in detail; you approve that plan before any code is written.

Useful extras:
- At the end of each stage: `Use a subagent to review this stage's changes against PLAN.md. Report only gaps that break a requirement or the "Ready when" check.`
- Before a release: `/code-review`

## Before you start
- Flutter (stable channel); `flutter doctor` shows no errors for the platforms you build.
- On your Mac: Xcode 26 or newer (iOS, macOS) and Android Studio (Android).
- A GitHub account and Claude Code.
- For phone tests: an Android phone or emulator, and an iPhone on iOS 26 or newer.
- About 5 friends who agree to try the app, and for squads a few groups of 2–4 friends.

## Fixed rules
| Topic | Rule |
| --- | --- |
| Stack | Flutter, one codebase for 6 platforms |
| 30-second rule | Each sound plays max 30 s, then the next one starts; it rotates until the alarm is stopped or snoozed; total cap 10 min (default) |
| Stopping | Alone: a short wake-up task. Squad: every squad mate's code. The cap and an emergency stop (hold Stop for 5 s) always end a ring (D12) |
| Squads | 2–6 people who share an alarm; they join by link or QR code; no accounts, no server |
| Snooze | 5 min (default, changeable); alone only, because a squad stops together |
| Sounds | Only original or properly licensed audio (allowed licenses: CLAUDE.md) |
| UI language | English only |
| Data | Local-first: no accounts, nothing uploaded. Test results leave a device only when the tester copies or exports them |
| Testers | Friends who agree to take part; we collect no names |
| Order | By question: each stage ends with a test on real people (D11); alone first, then squads (D12) |

## What studies suggest
Starting points for our questions, not proof that a feature works for our users.
- **Rotation:** the sleeping brain responds more strongly to an unfamiliar voice, and the response fades as the voice becomes familiar (Ameen et al., J Neurosci 2022, 17 people).
- **Gentle start:** alarm sounds rated melodic were linked with less morning grogginess than neutral ones (McFarlane et al., PLOS ONE 2020, 50 people, self-report).
- **Escalation:** a gradually rising alarm was linked with better morning mood in a 14-night home study (Yang, Cera & Pauletto, KTH).
- **Voice messages:** a mother's-voice alarm woke 86–91% of children vs 53% for a tone alarm (Smith et al., J Pediatrics 2018, ages 5–12).
- **Moving on waking:** a 30-second burst of exercise right after waking made people feel less sleepy, though it did not improve their test scores (lab study, 2021, 15 people).
- **Adaptive rotation:** 55.6% of over 3 million tracked nights ended with snooze (Robbins et al., Scientific Reports 2025).
- **Keep Snooze:** 30 min of snoozing did not hurt regular snoozers in a lab study (Sundelin et al., J Sleep Research 2023).
- **Wake-up tasks such as math:** we found no study that tests whether they help people wake up. Our tests will show which tasks work.
- **Same sound or rotation:** we found no study comparing "same sound every day" with "a new sound every morning". The app can collect that data.

---

## Stage 0 · Foundation — done
The empty app builds and the web test version is online. Stages 0 and 1 are the base every question needs, so they had no test with people.
- [x] 0.1 Create the app in this folder: `flutter create --project-name shuffle_alarm --org com.<yourname> --platforms=android,ios,web,macos,windows,linux .` Material 3 theme, app name "Shuffle Alarm".
- [x] 0.2 Strict lints (`very_good_analysis` or `flutter_lints`), the folder structure from CLAUDE.md, and `docs/DECISIONS.md`.
- [x] 0.3 App shell with go_router and Riverpod: bottom tabs Alarms, Library, Insights, plus a Settings page.
- [x] 0.4 GitHub repo + GitHub Actions: every push runs `flutter analyze` and `flutter test`; every push to `main` builds the web app and deploys it (GitHub Pages for a public repo; Cloudflare Pages or Firebase Hosting for a private repo).
- [x] 0.5 Visual identity "Dawn": own night and morning palette, bundled fonts (Fraunces, Manrope), floating tab bar, large titles, illustrated empty states; text contrast checked by a test.

## Stage 1 · Core engine — done
The rules every platform shares, in pure Dart: `flutter test test/core` passes, with tests for every rule, including "no clip over 30 s" and "no sound twice in a row".
- [x] 1.1 Models: `Alarm` (id, time, repeat days, label, enabled, genres, gentleStart, experimentGroup), `Sound` (id, title, source: builtin/user/voice, genre, intensity 1–3, duration, clipStart), `RingSession`, `RingEvent` (soundId, startedAt, endedAt, action: stop/snooze/timeout).
- [x] 1.2 Clip rule: a clip window never exceeds 30 s; bundled clips never exceed 29 s.
- [x] 1.3 Shuffle bag: no sound repeats until every sound in the pool has played, and never the same sound twice in a row (also across bag refills).

The rest of the old Phase 1 moved (D11): the ring sequence to Stage 2, escalation and adaptive weights to "Questions to test later".

## Stage 2 · Do wake-up tasks get people out of bed? — current
**Question:** when Stop opens a short task built on the sounds or on movement, can half-awake people do it quickly, and would they want it on their real alarm?

**Build:**
- [x] 2.1 Ring sequence: `buildRingSequence(alarm, pool, seed)` in `lib/core/` gives the clips of one ring in order: sounds of the alarm's genres from a shuffle bag seeded with `seed`, cut by the clip rule, until they cover the ring cap (10 min by default). The same seed gives the same sequence; empty clips are skipped; an empty pool gives an empty sequence.
- [x] 2.2 Placeholder sounds: a script in `tool/` makes 9 original clips that are easy to tell apart (for example birds, bells, drums; 3 per intensity level 1–3; synthesized, max 29 s) and `assets/library/manifest.json` with license `original`; a loader in `lib/data/` turns the manifest into sounds. No downloads.
- [x] 2.3 New look "Clock Radio", replacing "Dawn": the app looks like a bedside clock radio. Material buttons become keys that sink when pressed (an orange main key, neutral keys, small icon keys), times and codes show on a dark display with amber digits, the tabs are keys in a tray (the open one stays pressed), and pages are flat. Martian Mono and Onest are bundled with their OFL licenses. Every current screen in light and dark; a test keeps text contrast at WCAG AA and key outlines at 3:1.
- [x] 2.4 Wake-up tasks in `lib/core/`, tests first: "Which sound is playing?" (pick it among 3, three times in a row), "Catch the change" (the sounds switch at random moments; tap within 1.5 s of a switch, three times) and "Move" (30 s of movement, counted from the motion sensor). Each task has a time limit and an easier fallback.
- [ ] 2.5 Try a ring with a task: a "Try a ring" button on the Alarms tab rings now or at a random moment in the next 5 minutes. The ringing screen shows a big clock, the sound title, Stop and Snooze; Stop starts a random task ("Move" only where the device has a motion sensor) while the sounds keep rotating; holding Stop for 5 s is the emergency stop; the 10-min cap ends the ring. Sound and motion go through `SoundPlayer` and `MotionSensor` interfaces in `lib/platform/`.
- [ ] 2.6 Results and tester kit: after each try, the time from ring to stop, the task, mistakes and sounds played, with a "Copy my results" button (numbers only, nothing is sent); tester instructions and questions in `docs/testing/stage-2.md`.

**Ready when:** on the live site, "Try a ring" rings at the chosen moment with rotating sounds (each at most 29 s, never the same one twice in a row); Stop opens a task, and the ring goes on until the task is done, the emergency stop or the cap; every task can be finished in Chrome, Edge and a phone browser, and "Move" works on a phone.

**Test with people:** 5 friends · daytime · lying down with eyes closed until a ring comes at a random moment · each task once.
**Ask:** Which task got you up fastest? Which one was annoying or too hard half-awake? How did the sounds feel? Would you put a task on your real alarm?
**Pass if:** most testers finish each task within a minute, and at least 3 of 5 would put a task on their real alarm.
**If not:** change or drop the task that failed and test again. Math and other classic tasks wait until testers ask for them.

## Stage 3 · Do friends like stopping an alarm together? — next, rough
**Question:** when the alarm stops only after everyone has entered each other's codes, is it fun, and does it get the whole squad up?

**Build (rough):**
- Squad codes in `lib/core/`: a random squad secret; each member's 3-digit code for every 30-s window, computed on the device like two-factor codes; a check that also accepts the previous window, for clocks that differ a little.
- Make or join a squad: a name, 2–6 members, an alarm time; the others join with a link or QR code that carries the secret, and nothing goes to a server.
- Try a ring together: each phone shows its own code and fields for the others' codes, and stops when all are in. After 3 minutes, "Stop alone" opens a harder solo task. The emergency stop and the cap still work. No Snooze in a squad.
- Squad recap: who was up first, how long the whole squad took, who stopped alone.

**Test with people:** 3–4 groups of 2–4 friends · daytime · once in one room, once apart over a phone call.
**Pass if:** most groups are all stopped within 3 minutes, and at least half of the people want it for real mornings.

## Questions to test later
Each one becomes a stage only when the findings so far say it is worth it; the order is a first guess. The notes keep what we already know about building it.
- **Do people get up with it on real mornings?** Storage (drift, works on web) for alarms and ring sessions; Alarms screen: list, add/edit (time, repeat days, label, task or squad), on/off switch, "rings in 7 h 20 min"; web alarm: "Arm alarms" button (unlocks audio), clock check every second, banner "Keep this tab open", screen wake lock if the browser supports it; every RingEvent logged; the Insights tab lists the last 14 mornings (time to stop, snoozes, sounds played) with "Copy my results". Ready when an alarm set 1 minute ahead rings after "Arm alarms" (on time when the tab is visible, at most about 1 minute late in a background tab) and the web part of the alarm test checklist passes. Test: 3 mornings, alone and in squads, with the usual alarm as a backup 15 minutes later.
- **Will people trust it as their only alarm on an Android phone?** First a spike: the `alarm` package vs a small Kotlin plugin (`setAlarmClock` + foreground service + full-screen intent), recorded in `docs/DECISIONS.md`. Then single-fire alarms, rescheduled after each ring, after a reboot and after a time or time-zone change; ringing over the lock screen, with a foreground service that plays the rotation, and tasks and squad codes shown there too; permission onboarding (notifications, exact alarms, full-screen notifications, battery-optimization tips). Test: the alarm test checklist on a real phone, then a week as the testers' main alarm, with a backup.
- **Does a gentle start feel better?** Escalation: the first sound is intensity 1 (gentle, melodic), each next one is one level stronger until level 3; a volume per level (start values 40% → 70% → 100%) where the platform allows it; a "Gentle start" switch, on by default; a check-in after the stop: "How hard was it to get up? (1–5)". Test: mornings with and without it, in random order.
- **Do voices of loved ones wake people better than music?** Record up to 30 s, or import a voice message sent by chat (share sheet or file picker) and trim it to 30 s; give it a name ("Mom", "Best friend") and use it in the rotation. A squad mate can send you one this way. Test: voice mornings vs music mornings.
- **Does rotation beat the same sound every morning?** Experiment mode: 4 weeks, 2 weeks "same sound" and 2 weeks "rotation" in random order; a check-in after the stop; tracks time to stop, snoozes and missed alarms; exports a CSV with one row per morning, only when the user taps Export; a consent screen, no names. Needs a phone alarm people trust.
- **Does the app learn which sounds work for you?** Adaptive weights: each sound starts at 1.0; the sound playing at Snooze × 0.8, at the stop × 1.1; weights stay between 0.2 and 3.0 (start values; tune with real data); weighted pick inside the shuffle bag; on by default, with "Why this sound?" and "Reset learning".
- **Do streaks and new sounds keep people on time?** A streak for each alarm and squad; every week of on-time mornings unlocks new sounds, so the rotation stays unfamiliar.
- **Do people want more kinds of tasks?** Math, memory or typing as options, only if testers ask for them.
- **Do people want real music: genres and their own songs?** Genres v1: Pop, Rock, Hip-Hop, Electronic, Lo-fi, Classical, Jazz, Acoustic, plus Nature sounds, at least 8 clips each. `docs/MUSIC_SOURCING.md`: allowed licenses, sources (Freesound with the CC0 filter; Free Music Archive and Incompetech after checking each track's license; Pixabay Music only after reading its Content License) and proof (license URL + date saved); you choose and download tracks, Claude Code processes them. `tool/prepare_audio.sh` (ffmpeg): cut to max 29 s, 0.5 s fade in/out, the same loudness for all clips (e.g. −14 LUFS), `.mp3` (Android, desktop, web) and `.caf` (iOS, in a format iOS alarm sounds accept). Manifest fields: id, title, artist, genre, intensity (1–3), file, durationSec, license, sourceUrl, attribution. `tool/check_licenses.dart` runs in CI and fails if any audio file has no manifest entry, a disallowed license, or is longer than 29 s. Credits screen with all attributions (required for CC BY); Library screen: browse by genre, preview, choose genres per alarm. Own songs (mp3, m4a, wav): pick a 30-s part with a start slider and preview; stored only on the device.
- **Can an iPhone ring a rotation with the app closed?** iOS 26+, AlarmKit. First a spike on a real iPhone: (a) a bundled `.caf` plays as the alarm sound; (b) a chain of alarms 30 s apart with different sounds, where Stop cancels the rest; (c) can a user song or voice recording be the alarm sound?; (d) how many alarms can be scheduled at once?; (e) AlarmKit always shows a system Stop button, so can the chain keep ringing until the task or the squad codes are done in the app? Then `IosAlarmScheduler` with the chosen plugin (`flutter_alarmkit` ships a setup skill for Claude Code), `NSAlarmKitUsageDescription` in Info.plist, a permission screen, and rotation through the alarm chain (escalation = clips ordered from gentle to strong). If (c) fails, user songs and voice messages play inside the app after the user opens the alarm, and the UI explains this. Test: the alarm test checklist with the phone on silent.
- **Do people want it on their computer?** macOS, Windows and Linux: tray icon and "Launch at login"; closing the window keeps the app running in the tray; a scheduler that checks the clock every second and brings the ringing window to the front; the note "Your computer must be awake for alarms to ring." Computers have no motion sensor, so they get the sound tasks. macOS is built on a Mac, Windows and Linux in GitHub Actions. Test: the alarm rings with the main window closed on all three systems.
- **Will strangers install it and keep it?** A public beta: app icon, splash screen, store screenshots (English); a privacy policy (local-first, no data collected) on the web site; Play Console declarations (exact alarms, full-screen intent) and the internal testing track; TestFlight (needs a paid Apple Developer account); a signed and notarized macOS build, a Windows installer (MSIX), a Linux AppImage or Flatpak; a final check with `/code-review`, the license check and the alarm test checklist on every platform.

Not planned yet: accounts and cloud sync; seeing live which squad mates are up (needs a server); sending a voice message straight to a friend's alarm (needs a server and moderation); a bedtime reminder (putting off bedtime is linked with worse sleep); more genres; smart wake-up in light sleep (needs sleep tracking; check the evidence first).

## Alarm test checklist
Any change to scheduling or ringing must pass this on every affected platform (CLAUDE.md).
- **Every platform:** each way to end a ring works: the task, the squad codes, "Stop alone", the emergency stop (hold Stop for 5 s) and the 10-min cap.
- **Web:** tab visible · tab in the background (at most about 1 minute late) · after a reload, the app asks to arm alarms again.
- **Phone:** app open · in the background · swiped away · phone locked · after a reboot · Do Not Disturb on · phone idle overnight.
- **Desktop:** main window closed, app in the tray · computer awake.

## Progress log
<!-- Claude Code adds one line per finished task or stage: date, task ID, short note. -->
- 2026-10-28 · 0.1 · Flutter 3.47.8 app for 6 platforms (org `com.adilz`), Material 3 light/dark theme, "Shuffle Alarm" name on every platform; iOS/macOS name changes not checked until a Mac build.
- 2026-10-29 · 0.2 · `very_good_analysis` 11.0.0 (rule set locked, `public_member_api_docs` off), CLAUDE.md folder layout, `test/architecture_test.dart` guarding core/features imports, `docs/DECISIONS.md` started (D1–D3, L1).
- 2026-10-29 · 0.3 · App shell: go_router 18 tabs Alarms/Library/Insights (keep state), Settings on top, hash URLs, unknown URL → Alarms; router in a Riverpod provider; switched to the `material_ui` package (D4, D5, L2). Checked in the web release build.
- 2026-10-29 · 0.5 · "Dawn" look (D6): night/morning palette, Fraunces + Manrope bundled with OFL, floating tab bar, sunrise empty states, WCAG AA contrast test. Done before 0.4 at the user's request.
- 2026-10-29 · 0.4 · Public repo `adilkz21/shuffle-alarm`; `.github/workflows/ci.yml` runs a format check, analyze and test on every push (Flutter 3.47.8, lockfile enforced) and deploys `main` to GitHub Pages (D7). First run green; app shell checked at https://adilkz21.github.io/shuffle-alarm/. Phase 0 done.
- 2026-10-29 · 1.1 · Core models in `lib/core/`: `Alarm` (+ `AlarmTime`, `Weekday`, `ExperimentGroup`), `Sound` (+ `SoundSource`, `Intensity` levels 1–3), `RingEvent` (+ `RingAction`), and `RingSession` = one ring, whose outcome (stopped/snoozed/missed) comes from its last event (D8). Immutable value classes; `meta` and `collection` are now direct dependencies. 27 tests in `test/core/`.
- 2026-10-29 · 1.2 · Clip rule: `SoundClip.of(sound)` in `lib/core/sound_clip.dart` plays from the clip start to the end of the file, at most 30 s, or 29 s for bundled sounds; a bundled file over 29 s is cut, not rejected (D9). 12 tests, including "no clip over 30 s" on 10 000 random sounds; 39 tests in `test/core/`.
- 2026-10-29 · 1.3 · Shuffle bag: `ShuffleBag` in `lib/core/shuffle_bag.dart` plays every sound once per round in random order and never the same sound twice in a row, also when it refills (D10). Randomness comes only from the caller's `Random`, and sounds are deduplicated and sorted by id, so the same seed gives the same sequence. Empty pool → no sound; one sound → plays every turn; two → take turns. 10 tests, checked against planted bugs; 49 tests in `test/core/`.
- 2026-10-29 · plan · Phases by platform became stages by question, each ending with a test on real people (D11). Phase 0 → Stage 0 and tasks 1.1–1.3 → Stage 1, with the same numbers; the ring sequence moved to Stage 2, the rest of the old plan to "Questions to test later". `docs/DECISIONS.md` is grouped by topic and collects findings from the tests (F-numbers).
- 2026-10-29 · plan · Wake-up tasks and squads (D12): Stop opens a short task built on the sounds or on movement, and a squad's alarm stops only when everyone has entered each other's codes, with no accounts and no server. Stage 2 now tests the tasks alone, Stage 3 squads; real mornings in the browser moved to "Questions to test later".
- 2026-10-29 · 2.1 · Ring sequence: `buildRingSequence(alarm, pool, seed)` in `lib/core/ring_sequence.dart` gives the clips of one ring, as a list that can't be changed: sounds of the alarm's genres from a seeded shuffle bag, cut by the clip rule, until they cover the cap (`cap`, 10 min by default). The last clip plays whole and the ringing code stops at the cap; sounds whose clip is under 1 s (`SoundClip.minLength`) never enter the bag, so the loop always ends (D13). 20 tests, checked against 7 planted bugs; 69 tests in `test/core/`.
- 2026-10-29 · 2.2 · Placeholder sounds: `tool/make_placeholder_sounds.dart` synthesizes 9 original clips in pure Dart, 3 per intensity (Birds, Harp, Music Box · Xylophone, Video Game, Bell Tower · Drums, Alarm Clock, Fanfare), 22–24 s each, as 16-bit mono WAV at 22,050 Hz, and writes `assets/library/manifest.json`; `loadSoundLibrary` in `lib/data/sound_library.dart` turns it into sounds and leaves out bad entries, with an `assert` in debug builds (D14). 65 tests in `test/data/` (the loader, 1000 damaged manifests, the bundled files); 18 of 19 planted bugs caught, the 19th only changed a message; 162 tests in all.
- 2026-10-30 · 2.3 · "Clock Radio" look (D15) replaces "Dawn": `KeyBorder` makes every Material button a key that sinks when pressed (orange `FilledButton`, neutral `OutlinedButton`, small `IconButton`), plus `DisplayPanel`, `EmptyState` with dashes on the display, `KeyTabBar` and `AppPage`; `DeviceColors` and `lib/ui/tokens.dart` hold the extra colors and sizes; Martian Mono and Onest replace Fraunces and Manrope, with OFL licenses, and Settings gets "View licenses". Text contrast AA and key outlines 3:1 checked by a test in both modes; web build checked at phone, desktop and landscape sizes, light and dark. 217 tests in all.
- 2026-10-30 · 2.4 · Wake-up tasks in `lib/core/wake_up_task.dart` (D16): "Which sound is playing?" (3 in a row, a new sound after each answer, 60 s), "Catch the change" (switches every 4–10 s, tap within 1.5 s, 3 times, a tap at another moment takes back a catch, 60 s), "Move" (30 s of movement, 90 s) and the shared fallback "Lit key" (press the lit key 5 times, no hearing or movement, 60 s); `possibleWakeUpTasks` says which can start. 103 tests; 72 of 75 planted bugs caught, the other 3 changed nothing a person could notice, and two of them showed redundant checks, now removed. 320 tests in all.

## References
- Unfamiliar voices in sleep: https://www.ncbi.nlm.nih.gov/pmc/articles/PMC8896625/
- Melodic alarms (PLOS ONE): https://doi.org/10.1371/journal.pone.0215788
- Rising alarm (KTH): https://dael.euracoustics.org/confs/fa2026/data/articles/000156.pdf
- Mother's-voice smoke alarm: https://www.nationwidechildrens.org/newsroom/news-releases/2018/10/smoke-alarm-study
- Exercise on waking and sleep inertia (lab study): https://pubmed.ncbi.nlm.nih.gov/34606883/
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
