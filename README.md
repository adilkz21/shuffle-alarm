# Shuffle Alarm

An alarm clock that wakes you with a rotating set of different sounds. Each sound plays for at most 30 seconds, then the next one starts, until you tap Stop or Snooze.

One Flutter codebase for web, Android, iOS, macOS, Windows and Linux. The web version is the test version.

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
