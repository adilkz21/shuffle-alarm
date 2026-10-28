# Shuffle Alarm

[![CI](https://github.com/adilkz21/shuffle-alarm/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/adilkz21/shuffle-alarm/actions/workflows/ci.yml)

An alarm clock that wakes you with a rotating set of different sounds. Each sound plays for at most 30 seconds, then the next one starts, until you tap Stop or Snooze.

One Flutter codebase for web, Android, iOS, macOS, Windows and Linux. The web version is the test version.

- Web test version: https://adilkz21.github.io/shuffle-alarm/
- Roadmap and task checklist: [PLAN.md](PLAN.md)
- Project rules: [CLAUDE.md](CLAUDE.md)

## Run

```bash
flutter pub get
flutter run -d chrome
```

No Chrome on Windows? Use `flutter run -d edge`.

## Checks

```bash
dart format .
flutter analyze
flutter test
```

GitHub Actions runs the same checks on every push ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)). A push to `main` that passes them also publishes the web version.
