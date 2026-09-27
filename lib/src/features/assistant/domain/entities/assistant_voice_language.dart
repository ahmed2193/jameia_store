/// The language the customer talks in — Arabic or English, the app's two.
/// Chosen apart from the app's own language: many customers read the app
/// in English and speak Arabic, and a recognizer set to the wrong language
/// turns speech into the wrong words.
enum AssistantVoiceLanguage {
  arabic('ar'),
  english('en');

  const AssistantVoiceLanguage(this.code);

  /// The language code: `ar`, `en`.
  final String code;

  /// The one for the app's [languageCode] — English for any other.
  static AssistantVoiceLanguage of(String languageCode) =>
      tryParse(languageCode) ?? english;

  /// The one for [code]; `null` for any other.
  static AssistantVoiceLanguage? tryParse(String code) {
    final wanted = code.toLowerCase();
    for (final language in values) {
      if (language.code == wanted) return language;
    }
    return null;
  }

  /// The other of the two — what the language switch offers.
  AssistantVoiceLanguage get other => this == arabic ? english : arabic;
}
