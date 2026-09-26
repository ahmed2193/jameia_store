/// The languages the Settings language control offers, in display order,
/// with the i18n key of each segment's label.
enum SettingsLanguage {
  english('en', 'settings.lang_chip_en'),
  arabic('ar', 'settings.arabic');

  const SettingsLanguage(this.code, this.labelKey);

  final String code;
  final String labelKey;

  /// The option for [code]; English for a code the control does not offer.
  static SettingsLanguage of(String code) {
    for (final language in values) {
      if (language.code == code) return language;
    }
    return english;
  }
}
