import 'package:intl/intl.dart';

/// Where the network layer reads the current UI language from, without a
/// `BuildContext`. Drives the `Accept-Language` header so the backend resolves
/// localized catalogue strings + error messages in the user's language.
abstract class LocaleProvider {
  /// Two-letter language code (`en` / `ar`).
  String get languageCode;
}

/// Reads `Intl.defaultLocale`, which `LocalizationCubit` + the app root keep in
/// sync with easy_localization on launch and on every language switch — so
/// there is exactly one source of truth and nothing to duplicate here.
class IntlLocaleProvider implements LocaleProvider {
  const IntlLocaleProvider();

  static const String _fallback = 'en';

  @override
  String get languageCode {
    final locale = Intl.defaultLocale;
    if (locale == null || locale.isEmpty) return _fallback;
    return Intl.shortLocale(locale);
  }
}
