import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Registers the SIL Open Font Licences of the bundled fonts with
/// [LicenseRegistry], so they travel with the fonts (an OFL condition) and
/// show on About → Open-source licences.
abstract final class FontLicenses {
  static const String _dir = 'assets/licenses';

  /// Licence file → the packages it covers.
  static const Map<String, List<String>> _files = {
    'OFL-Fredoka.txt': ['Fredoka (HeroDigits, the Hero wordmarks)'],
    'OFL-BalooBhaijaan2.txt': ['Baloo Bhaijaan 2 (the Arabic Hero wordmark)'],
    'OFL-NotoSans.txt': ['Noto Sans'],
    'OFL-NotoSansArabic.txt': ['Noto Sans Arabic UI'],
  };

  /// Call once at start-up; the files are read only when the licences page
  /// asks for them.
  static void register() => LicenseRegistry.addLicense(_entries);

  static Stream<LicenseEntry> _entries() async* {
    for (final MapEntry(key: file, value: packages) in _files.entries) {
      final text = await rootBundle.loadString('$_dir/$file');
      yield LicenseEntryWithLineBreaks(packages, text);
    }
  }
}
