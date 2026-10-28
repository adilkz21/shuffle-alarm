import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shuffle_alarm/ui/fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the font licenses are on the licenses page', () async {
    LicenseRegistry.reset();
    addTearDown(LicenseRegistry.reset);

    addFontLicenses();
    final entries = await LicenseRegistry.licenses.toList();

    expect(
      entries.expand((entry) => entry.packages),
      containsAll([serifFamily, sansFamily]),
    );
    for (final entry in entries) {
      final text = entry.paragraphs.map((p) => p.text).join(' ');
      expect(text, contains('SIL Open Font License'));
    }
  });
}
