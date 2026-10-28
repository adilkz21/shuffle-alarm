// Guards the folder rules from CLAUDE.md that lints can't check.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Flutter itself, any `flutter*` package, the Material and Cupertino
/// packages, or the engine's `dart:ui`.
final _flutterUri = RegExp(
  r'''['"](package:(flutter\w*|material_ui|cupertino_ui)/|dart:ui)''',
);

/// Any app file outside `lib/core/`.
final _appUriOutsideCore = RegExp('''['"]package:shuffle_alarm/(?!core/)''');

/// A platform implementation; features must go through the interfaces.
final _platformImplementationUri = RegExp(
  '''['"]package:shuffle_alarm/platform/(android|ios|desktop|web)/''',
);

void main() {
  test('lib/core is pure Dart and imports no other app layer', () {
    expect(_linesMatching('lib/core', _flutterUri), isEmpty);
    expect(_linesMatching('lib/core', _appUriOutsideCore), isEmpty);
  });

  test('lib/features reaches platform code only through interfaces', () {
    expect(_linesMatching('lib/features', _platformImplementationUri), isEmpty);
  });

  test('the patterns flag the right URIs', () {
    bool flags(RegExp pattern, String uri) =>
        pattern.hasMatch("import '$uri';");

    expect(flags(_flutterUri, 'package:flutter/foundation.dart'), isTrue);
    expect(
      flags(_flutterUri, 'package:flutter_riverpod/riverpod.dart'),
      isTrue,
    );
    expect(flags(_flutterUri, 'package:material_ui/material_ui.dart'), isTrue);
    expect(flags(_flutterUri, 'dart:ui'), isTrue);
    expect(flags(_flutterUri, 'dart:math'), isFalse);

    expect(
      flags(_appUriOutsideCore, 'package:shuffle_alarm/data/db.dart'),
      isTrue,
    );
    expect(
      flags(_appUriOutsideCore, 'package:shuffle_alarm/core/a.dart'),
      isFalse,
    );

    const impl = 'package:shuffle_alarm/platform/web/scheduler.dart';
    const api = 'package:shuffle_alarm/platform/alarm_scheduler.dart';
    expect(flags(_platformImplementationUri, impl), isTrue);
    expect(flags(_platformImplementationUri, api), isFalse);
  });
}

/// `path:line: text` for every line of the Dart files under [dir] that
/// matches [pattern]. Fails if [dir] is missing, so the guard can't go quiet.
List<String> _linesMatching(String dir, RegExp pattern) {
  final directory = Directory(dir);
  if (!directory.existsSync()) fail('$dir is missing');
  return [
    for (final file in directory.listSync(recursive: true).whereType<File>())
      if (file.path.endsWith('.dart'))
        for (final (i, line) in file.readAsLinesSync().indexed)
          if (pattern.hasMatch(line)) '${file.path}:${i + 1}: ${line.trim()}',
  ];
}
