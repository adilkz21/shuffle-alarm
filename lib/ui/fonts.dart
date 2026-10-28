import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Soft serif for page titles, headings and big numbers.
const serifFamily = 'Fraunces';

/// Clean sans-serif for everything else.
const sansFamily = 'Manrope';

/// Adds the bundled fonts' OFL licenses to the app's licenses page. The
/// license requires them to travel with the fonts.
void addFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final (family, folder) in const [
      (serifFamily, 'fraunces'),
      (sansFamily, 'manrope'),
    ]) {
      final text = await rootBundle.loadString('assets/fonts/$folder/OFL.txt');
      yield LicenseEntryWithLineBreaks([family], text);
    }
  });
}
