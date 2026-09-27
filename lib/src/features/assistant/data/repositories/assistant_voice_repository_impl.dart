import 'package:dartz/dartz.dart';

import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/assistant_voice_access.dart';
import '../../domain/entities/assistant_voice_event.dart';
import '../../domain/entities/assistant_voice_language.dart';
import '../../domain/repositories/assistant_voice_repository.dart';
import '../datasources/assistant_voice_data_source.dart';
import '../datasources/assistant_voice_settings_local_data_source.dart';
import '../mappers/assistant_voice_mapper.dart';

class AssistantVoiceRepositoryImpl
    with BaseRepositoryMixin
    implements AssistantVoiceRepository {
  const AssistantVoiceRepositoryImpl(this._source, this._settings);

  final AssistantVoiceDataSource _source;
  final AssistantVoiceSettingsLocalDataSource _settings;

  @override
  Future<Either<Failure, AssistantVoiceAccess?>> prepare() =>
      execute(() async => (await _source.prepare())?.toEntity());

  @override
  Future<Either<Failure, AssistantVoiceAccess>> requestAccess() =>
      execute(() async => (await _source.requestAccess()).toEntity());

  @override
  Stream<AssistantVoiceEvent> listen({required String languageCode}) =>
      guardStream(
        _source
            .listen(languageCode: languageCode)
            .map((update) => update.toEntity()),
      );

  @override
  Future<Either<Failure, Unit>> finish() => execute(() async {
    await _source.finish();
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> cancel() => execute(() async {
    await _source.cancel();
    return unit;
  });

  @override
  Future<Either<Failure, Unit>> openSettings() => execute(() async {
    await _source.openSettings();
    return unit;
  });

  /// A code this app no longer knows counts as no choice.
  @override
  Future<Either<Failure, AssistantVoiceLanguage?>> savedLanguage() =>
      execute(() {
        final code = _settings.readLanguage();
        return code == null ? null : AssistantVoiceLanguage.tryParse(code);
      });

  @override
  Future<Either<Failure, Unit>> saveLanguage(AssistantVoiceLanguage language) =>
      execute(() async {
        await _settings.writeLanguage(language.code);
        return unit;
      });
}
