import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/session_store.dart';

/// Local (offline) persistence of the chosen app language, plus the one
/// session fact the language flow needs: whether a customer is signed in (so
/// the choice can be mirrored to the account).
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

  /// `true` when an API session is stored (the profile can be updated).
  Future<bool> isSignedIn();
}

class LangLocalDataSourceImpl implements LangLocalDataSource {
  const LangLocalDataSourceImpl(this._storage, this._session);

  static const String _langKey = 'app_language';

  final LocalStorage _storage;
  final SessionStore _session;

  @override
  Future<String> getSavedLang() async => _storage.getString(_langKey) ?? '';

  @override
  Future<void> changeLang(String langCode) =>
      _storage.setString(_langKey, langCode);

  @override
  Future<bool> isSignedIn() => _session.isSignedIn;
}
