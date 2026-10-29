# Shuffle Alarm

[![CI](https://github.com/adilkz21/shuffle-alarm/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/adilkz21/shuffle-alarm/actions/workflows/ci.yml)

An alarm clock that wakes you with a rotating set of different sounds: each one plays for at most 30 seconds, then the next one starts. You can't just tap Stop: alone, you stop it with a short wake-up task; in a squad of friends, it stops only when everyone is up.

One Flutter codebase for web, Android, iOS, macOS, Windows and Linux. The web version is the test version.

- Web test version: https://adilkz21.github.io/shuffle-alarm/
- Plan, in short stages that each end with a test on real people: [PLAN.md](PLAN.md)
- Decisions and test findings: [docs/DECISIONS.md](docs/DECISIONS.md)
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
