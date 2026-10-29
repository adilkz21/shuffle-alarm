import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:shuffle_alarm/core/sound.dart';

/// The asset that lists every sound bundled with the app.
const _manifestAsset = 'assets/library/manifest.json';

/// The folder the `file` of each manifest entry is in.
const _libraryFolder = 'assets/library/';

/// The sounds bundled with the app, as `assets/library/manifest.json` lists
/// them. Why it works this way: docs/DECISIONS.md (D14).
@immutable
final class SoundLibrary {
  /// The library that [manifest], the text of a manifest file, lists.
  ///
  /// Never throws: data from a file is checked where it is loaded (D8). An
  /// entry that breaks the schema is left out, and so is an entry whose id
  /// an earlier entry already has; [problems] says why. A manifest that is
  /// not a JSON object with a `sounds` list gives no sounds.
  factory fromManifest(String manifest) {
    final Object? json;
    try {
      json = jsonDecode(manifest);
    } on FormatException catch (error) {
      return SoundLibrary._(const [], [
        'The manifest is not JSON: ${error.message}',
      ]);
    }
    if (json case {'sounds': final List<Object?> sounds}) {
      final entries = <LibraryEntry>[];
      final problems = <String>[];
      final ids = <String>{};
      for (final (i, item) in sounds.indexed) {
        try {
          final entry = _entryOf(item);
          final id = entry.sound.id;
          if (!ids.add(id)) throw _BadEntry('an earlier entry has the id $id');
          entries.add(entry);
        } on _BadEntry catch (bad) {
          final name = switch (item) {
            {'id': final String id} => ' ($id)',
            _ => '',
          };
          problems.add('sounds[$i]$name: ${bad.reason}');
        }
      }
      return SoundLibrary._(
        List.unmodifiable(entries),
        List.unmodifiable(problems),
      );
    }
    return const SoundLibrary._([], [
      'The manifest must be a JSON object with a "sounds" list.',
    ]);
  }

  const new _(this.entries, this.problems);

  /// The good entries, in the order of the manifest.
  final List<LibraryEntry> entries;

  /// Why entries were left out, one line each; empty for a good manifest.
  final List<String> problems;

  /// The sounds alone, such as the pool of a ring.
  List<Sound> get sounds => [for (final entry in entries) entry.sound];
}

/// A sound of the library, with where its file is and whom to credit.
@immutable
final class LibraryEntry {
  const new({
    required this.sound,
    required this.asset,
    required this.artist,
    required this.license,
    required this.sourceUrl,
    required this.attribution,
  });

  /// A [SoundSource.builtin] sound.
  final Sound sound;

  /// The asset key of its audio file, such as
  /// `assets/library/placeholder/birds.wav`.
  final String asset;

  /// Who made it; `Shuffle Alarm` for the sounds we make.
  final String artist;

  /// Such as `original` (made by us) or `CC0`. CLAUDE.md lists the licenses
  /// allowed; the license check enforces them, not the loader.
  final String license;

  /// Where the file comes from; empty for the sounds we make.
  final String sourceUrl;

  /// The credit its license asks for; empty when it asks for none.
  final String attribution;

  @override
  bool operator ==(Object other) =>
      other is LibraryEntry &&
      other.sound == sound &&
      other.asset == asset &&
      other.artist == artist &&
      other.license == license &&
      other.sourceUrl == sourceUrl &&
      other.attribution == attribution;

  @override
  int get hashCode =>
      Object.hash(sound, asset, artist, license, sourceUrl, attribution);

  @override
  String toString() => 'LibraryEntry(${sound.id}, $asset, $license)';
}

/// The library that `assets/library/manifest.json` lists, read with
/// [loadString], such as `rootBundle.loadString`.
///
/// A release build never fails here: it leaves bad entries out and plays
/// the rest, and when the manifest can't be read at all, the library is
/// empty, so the ring plays its fallback sound (D13). A debug build stops at
/// an `assert` instead, so a bad manifest gets fixed before it ships (D8).
Future<SoundLibrary> loadSoundLibrary(
  Future<String> Function(String key) loadString,
) async {
  SoundLibrary library;
  try {
    library = SoundLibrary.fromManifest(await loadString(_manifestAsset));
  } on Object catch (error) {
    library = SoundLibrary._(const [], ["The manifest can't be read: $error"]);
  }
  assert(
    library.problems.isEmpty,
    '$_manifestAsset has problems:\n${library.problems.join('\n')}',
  );
  return library;
}

/// The entry [json] describes; throws [_BadEntry] when it breaks the schema.
LibraryEntry _entryOf(Object? json) {
  if (json is! Map<String, Object?>) {
    throw const _BadEntry('an entry must be a JSON object');
  }
  Object? field(String name) =>
      json.containsKey(name) ? json[name] : throw _BadEntry('no "$name"');
  String text(String name, {bool mayBeEmpty = false}) {
    final value = field(name);
    if (value is! String) throw _BadEntry('"$name" must be a string');
    if (!mayBeEmpty && value.trim().isEmpty) {
      throw _BadEntry('"$name" must not be empty');
    }
    return value;
  }

  final id = text('id');
  final title = text('title');
  final artist = text('artist');
  final genre = text('genre');

  final level = field('intensity');
  final intensity = Intensity.values
      .where((intensity) => intensity.level == level)
      .firstOrNull;
  if (intensity == null) {
    throw const _BadEntry('"intensity" must be 1, 2 or 3');
  }

  final file = text('file');
  final parts = file.split('/');
  if (file.contains(r'\') ||
      parts.any((part) => part.isEmpty || part == '.' || part == '..')) {
    throw const _BadEntry(
      '"file" must be a path inside $_libraryFolder, such as '
      '"placeholder/birds.wav"',
    );
  }

  // As a double, so a huge number can't overflow an int; a number too big
  // for a Duration becomes the longest one, and the clip rule cuts it.
  final seconds = field('durationSec');
  final microseconds = seconds is num
      ? seconds.toDouble() * Duration.microsecondsPerSecond
      : 0.0;
  if (!microseconds.isFinite || microseconds.round() < 1) {
    throw const _BadEntry('"durationSec" must be a positive number');
  }

  return LibraryEntry(
    sound: Sound(
      id: id,
      title: title,
      source: .builtin,
      genre: genre,
      intensity: intensity,
      duration: Duration(microseconds: microseconds.round()),
    ),
    asset: '$_libraryFolder$file',
    artist: artist,
    license: text('license'),
    sourceUrl: text('sourceUrl', mayBeEmpty: true),
    attribution: text('attribution', mayBeEmpty: true),
  );
}

/// Why a manifest entry can't be a sound.
final class _BadEntry implements Exception {
  const new(this.reason);

  final String reason;
}
