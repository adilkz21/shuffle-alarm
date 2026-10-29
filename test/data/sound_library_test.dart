import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shuffle_alarm/core/sound.dart';
import 'package:shuffle_alarm/data/sound_library.dart';

/// A good manifest entry for the sound `sound-<n>`.
Map<String, Object?> _entry(int n) => {
  'id': 'sound-$n',
  'title': 'Sound $n',
  'artist': 'Shuffle Alarm',
  'genre': 'placeholder',
  'intensity': n % 3 + 1,
  'file': 'placeholder/sound-$n.wav',
  'durationSec': 20 + n,
  'license': 'original',
  'sourceUrl': '',
  'attribution': '',
};

/// The text of a manifest that lists [entries].
String _manifest(List<Object?> entries) => jsonEncode({'sounds': entries});

/// The ids of the sounds in [library], in manifest order.
List<String> _ids(SoundLibrary library) => [
  for (final sound in library.sounds) sound.id,
];

/// The entry of `sound-1` with [field] set to [value].
Map<String, Object?> _with(String field, Object? value) => {
  ..._entry(1),
  field: value,
};

/// The entry of `sound-1` without [field].
Map<String, Object?> _without(String field) => {..._entry(1)}..remove(field);

/// Entries that break the schema, by what is wrong with them.
final _badEntries = <String, Object?>{
  'is a string': 'sound-1',
  'is null': null,
  'is a number': 1,
  'is a list': [_entry(1)],
  'has no id': _without('id'),
  'has an empty id': _with('id', ''),
  'has a blank id': _with('id', '  '),
  'has a number as id': _with('id', 1),
  'has no title': _without('title'),
  'has an empty title': _with('title', ''),
  'has a list as title': _with('title', ['Sound 1']),
  'has no artist': _without('artist'),
  'has an empty artist': _with('artist', ''),
  'has no genre': _without('genre'),
  'has an empty genre': _with('genre', ''),
  'has no intensity': _without('intensity'),
  'has intensity 0': _with('intensity', 0),
  'has intensity 4': _with('intensity', 4),
  'has intensity 2.5': _with('intensity', 2.5),
  'has intensity "2"': _with('intensity', '2'),
  'has no file': _without('file'),
  'has an empty file': _with('file', ''),
  'has a file path from the root': _with('file', '/placeholder/sound-1.wav'),
  'has a file outside the library': _with('file', '../sound-1.wav'),
  'has a file that climbs out': _with('file', 'placeholder/../../a.wav'),
  'has a file with "."': _with('file', './sound-1.wav'),
  'has a file with an empty part': _with('file', 'placeholder//sound-1.wav'),
  'has a folder as file': _with('file', 'placeholder/'),
  'has a file with backslashes': _with('file', r'placeholder\sound-1.wav'),
  'has no durationSec': _without('durationSec'),
  'has durationSec 0': _with('durationSec', 0),
  'has a negative durationSec': _with('durationSec', -1),
  'has durationSec under a microsecond': _with('durationSec', 0.0000001),
  'has durationSec "24"': _with('durationSec', '24'),
  'has durationSec true': _with('durationSec', true),
  'has no license': _without('license'),
  'has an empty license': _with('license', ''),
  'has no sourceUrl': _without('sourceUrl'),
  'has null as sourceUrl': _with('sourceUrl', null),
  'has no attribution': _without('attribution'),
  'has a number as attribution': _with('attribution', 0),
};

/// Any JSON value: mostly simple ones, some lists and objects.
Object? _randomValue(Random random, [int depth = 0]) => switch (random.nextInt(
  depth > 1 ? 10 : 12,
)) {
  0 => null,
  1 => random.nextBool(),
  2 => random.nextInt(7) - 2,
  3 => random.nextDouble() * 60 - 10,
  4 => const [0.0000001, 0.5, 2.0, 1e300][random.nextInt(4)],
  5 => '',
  6 => '  ',
  7 => 'placeholder/../sound.wav',
  8 => 'placeholder/sound-${random.nextInt(4)}.wav',
  9 => 'sound-${random.nextInt(4)}',
  10 => [
    for (var i = random.nextInt(3); i > 0; i--) _randomValue(random, depth + 1),
  ],
  _ => {'id': _randomValue(random, depth + 1)},
};

/// [entry] as it is, with one field changed or missing, or replaced by any
/// JSON value.
Object? _mutated(Random random, Map<String, Object?> entry) {
  final field = entry.keys.elementAt(random.nextInt(entry.length));
  return switch (random.nextInt(4)) {
    0 => entry,
    1 => {...entry}..remove(field),
    2 => {...entry, field: _randomValue(random)},
    _ => _randomValue(random),
  };
}

void main() {
  group('a manifest', () {
    test(
      'turns each entry into a built-in sound with its file and credits',
      () {
        final library = SoundLibrary.fromManifest(
          _manifest([
            {
              'id': 'placeholder-birds',
              'title': 'Birds',
              'artist': 'Shuffle Alarm',
              'genre': 'placeholder',
              'intensity': 1,
              'file': 'placeholder/birds.wav',
              'durationSec': 24.5,
              'license': 'CC BY 4.0',
              'sourceUrl': 'https://example.com/birds',
              'attribution': 'Birds by Shuffle Alarm',
            },
          ]),
        );

        expect(library.problems, isEmpty);
        expect(library.entries, [
          LibraryEntry(
            sound: Sound(
              id: 'placeholder-birds',
              title: 'Birds',
              source: .builtin,
              genre: 'placeholder',
              intensity: .gentle,
              duration: const Duration(seconds: 24, milliseconds: 500),
            ),
            asset: 'assets/library/placeholder/birds.wav',
            artist: 'Shuffle Alarm',
            license: 'CC BY 4.0',
            sourceUrl: 'https://example.com/birds',
            attribution: 'Birds by Shuffle Alarm',
          ),
        ]);
        expect(library.sounds, [library.entries.single.sound]);
      },
    );

    test('reads intensity 1 to 3 and whole or fractional seconds', () {
      final library = SoundLibrary.fromManifest(
        _manifest([
          {..._entry(0), 'intensity': 1, 'durationSec': 29},
          {..._entry(1), 'intensity': 2, 'durationSec': 0.000001},
          {..._entry(2), 'intensity': 3, 'durationSec': 1.25},
        ]),
      );

      expect(library.problems, isEmpty);
      expect(
        [for (final sound in library.sounds) sound.intensity],
        [Intensity.gentle, Intensity.medium, Intensity.strong],
      );
      expect(
        [for (final sound in library.sounds) sound.duration],
        [
          const Duration(seconds: 29),
          const Duration(microseconds: 1),
          const Duration(seconds: 1, milliseconds: 250),
        ],
      );
    });

    test('keeps its order and ignores fields it does not know', () {
      final library = SoundLibrary.fromManifest(
        _manifest([
          _entry(2),
          {
            ..._entry(0),
            'bpm': 120,
            'tags': ['calm'],
          },
          _entry(1),
        ]),
      );

      expect(library.problems, isEmpty);
      expect(_ids(library), ['sound-2', 'sound-0', 'sound-1']);
    });

    test('with no sounds gives an empty library without problems', () {
      final library = SoundLibrary.fromManifest('{"sounds": []}');

      expect(library.entries, isEmpty);
      expect(library.problems, isEmpty);
    });

    test('that is not a JSON object with a sounds list gives no sounds', () {
      for (final text in [
        '',
        'sounds',
        '{"sounds": [',
        'null',
        '42',
        '[]',
        '{}',
        '{"sound": []}',
        '{"sounds": null}',
        '{"sounds": {}}',
        '{"sounds": "birds"}',
      ]) {
        final library = SoundLibrary.fromManifest(text);

        expect(library.entries, isEmpty, reason: text);
        expect(library.problems, hasLength(1), reason: text);
      }
    });

    test("gives lists that can't be changed", () {
      final library = SoundLibrary.fromManifest(_manifest(['bad', _entry(0)]));

      expect(
        () => library.entries.add(library.entries.first),
        throwsUnsupportedError,
      );
      expect(() => library.problems.add('more'), throwsUnsupportedError);
    });
  });

  group('an entry that breaks the schema is skipped', () {
    for (final MapEntry(key: what, value: entry) in _badEntries.entries) {
      test('when it $what', () {
        final library = SoundLibrary.fromManifest(
          _manifest([_entry(0), entry, _entry(2)]),
        );

        expect(_ids(library), ['sound-0', 'sound-2']);
        expect(library.problems, [startsWith('sounds[1]')]);
      });
    }

    test('when its duration is too big to be a number', () {
      // JSON can say 1e400, but no double can hold it.
      final text = _manifest([_entry(0), _entry(1)])
          .replaceFirst('"durationSec":21', '"durationSec":1e400');
      final library = SoundLibrary.fromManifest(text);

      expect(_ids(library), ['sound-0']);
      expect(library.problems, [startsWith('sounds[1]')]);
    });

    test('when an earlier entry has its id, so the first one stays', () {
      final library = SoundLibrary.fromManifest(
        _manifest([
          _entry(0),
          {..._entry(1), 'id': 'sound-0'},
          _entry(2),
        ]),
      );

      expect(
        [for (final sound in library.sounds) sound.title],
        ['Sound 0', 'Sound 2'],
      );
      expect(library.problems, [
        allOf(startsWith('sounds[1]'), contains('sound-0')),
      ]);
    });

    test('but its id stays free for a later good entry', () {
      final library = SoundLibrary.fromManifest(
        _manifest([
          {..._entry(0), 'intensity': 9},
          _entry(0),
        ]),
      );

      expect(_ids(library), ['sound-0']);
      expect(library.problems, [startsWith('sounds[0]')]);
    });
  });

  test('1000 damaged manifests never throw, and no bad data gets in', () {
    final random = Random(1);
    for (var run = 0; run < 1000; run++) {
      final entries = List.generate(
        random.nextInt(6),
        (i) => _mutated(random, _entry(i)),
      );
      var text = _manifest(entries);
      final cut = run.isOdd && random.nextInt(4) == 0;
      if (cut) text = text.substring(0, random.nextInt(text.length));

      final library = SoundLibrary.fromManifest(text);

      // Every entry is either kept or named in one problem.
      if (!cut) {
        expect(
          library.entries.length + library.problems.length,
          entries.length,
          reason: 'run $run',
        );
      }
      final ids = <String>{};
      for (final LibraryEntry(:sound, :asset) in library.entries) {
        expect(ids.add(sound.id), isTrue, reason: 'run $run: ${sound.id}');
        expect(sound.source, SoundSource.builtin);
        expect(sound.duration, greaterThan(Duration.zero));
        for (final value in [sound.id, sound.title, sound.genre]) {
          expect(value.trim(), isNotEmpty, reason: 'run $run');
        }
        expect(asset, startsWith('assets/library/'));
        expect(asset.split('/'), isNot(contains('..')), reason: 'run $run');
      }
    }
  });

  group('loadSoundLibrary', () {
    test('reads assets/library/manifest.json', () async {
      final keys = <String>[];
      final library = await loadSoundLibrary((key) async {
        keys.add(key);
        return _manifest([_entry(0), _entry(1)]);
      });

      expect(keys, ['assets/library/manifest.json']);
      expect(_ids(library), ['sound-0', 'sound-1']);
    });

    // A release build skips what these tests stop at, as above.
    test('stops a debug build at a bad entry', () async {
      await expectLater(
        loadSoundLibrary((_) async => _manifest([_entry(0), 'bad'])),
        throwsA(
          isA<AssertionError>().having(
            (error) => error.message,
            'message',
            contains('sounds[1]'),
          ),
        ),
      );
    });

    test("stops a debug build when the manifest can't be read", () async {
      await expectLater(
        loadSoundLibrary(
          (key) async => throw FlutterError('Unable to load asset: "$key".'),
        ),
        throwsA(
          isA<AssertionError>().having(
            (error) => error.message,
            'message',
            contains('Unable to load asset'),
          ),
        ),
      );
    });
  });
}
