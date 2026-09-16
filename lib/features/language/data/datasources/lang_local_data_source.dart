import '../../../../core/storage/local_storage.dart';

/// Local (offline) persistence of the chosen app language.
///
/// Mirrors khayool's `LangLocalDataSource` (there backed by a Hive `langBox`);
/// here it uses the app's shared [LocalStorage] (shared_preferences) — the same
/// mediated store the cart uses — under key [_langKey].
///
/// easy_localization also persists the locale on its own, but reading THIS store
/// on launch keeps the startup locale independent of easy_localization's internal
/// prefs, so the [LocalizationCubit] owns a single source of truth.
abstract class LangLocalDataSource {
  /// The saved language code, or `''` when the user has never chosen one — so the
  /// caller can apply the app default instead of a hard-coded fallback.
  Future<String> getSavedLang();

  /// Persist the chosen language [langCode] (`en` / `ar`).
  Future<void> changeLang(String langCode);
}

class LangLocalDataSourceImpl implements LangLocalDataSource {
  final LocalStorage storage;
  LangLocalDataSourceImpl(this.storage);

  static const String _langKey = 'app_language';

  @override
  Future<String> getSavedLang() async => storage.getString(_langKey) ?? '';

  @override
  Future<void> changeLang(String langCode) =>
      storage.setString(_langKey, langCode);
}
