import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Monospace for digits, codes and key labels: the clock radio's display
/// and the writing on its keys.
const displayFamily = 'Martian Mono';

/// Sans-serif for titles and everything else.
const textFamily = 'Onest';

/// Adds the bundled fonts' OFL licenses to the app's licenses page. The
/// license requires them to travel with the fonts.
void addFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final (family, folder) in const [
      (displayFamily, 'martian_mono'),
      (textFamily, 'onest'),
    ]) {
      final text = await rootBundle.loadString('assets/fonts/$folder/OFL.txt');
      yield LicenseEntryWithLineBreaks([family], text);
    }
  });
}
