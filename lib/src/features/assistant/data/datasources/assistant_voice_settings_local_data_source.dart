import '../../../../core/error/exceptions.dart';
import '../../../../core/storage/local_storage.dart';

/// The voice settings kept on the device ([LocalStorage]): the language the
/// customer chose to talk in.
abstract class AssistantVoiceSettingsLocalDataSource {
  /// The language code the customer chose (`ar`, `en`); `null` when none.
  String? readLanguage();

  /// Throws [CacheException] when it could not be written.
  Future<void> writeLanguage(String code);
}

class AssistantVoiceSettingsLocalDataSourceImpl
    implements AssistantVoiceSettingsLocalDataSource {
  const AssistantVoiceSettingsLocalDataSourceImpl(this._storage);

  final LocalStorage _storage;

  static const String languageKey = 'assistant.voice.language.v1';

  @override
  String? readLanguage() => _storage.getString(languageKey);

  @override
  Future<void> writeLanguage(String code) async {
    if (!await _storage.setString(languageKey, code)) {
      throw const CacheException('Could not store the voice language');
    }
  }
}
