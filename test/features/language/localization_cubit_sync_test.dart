// The account-language mirror when the connection comes back: a sync the
// network swallowed is owed and sent again, once; one that got through, or
// one the server refused, is not.
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/features/language/domain/repositories/lang_repository.dart';
import 'package:hero_mart/src/features/language/domain/usecases/change_lang_usecase.dart';
import 'package:hero_mart/src/features/language/domain/usecases/get_saved_lang_usecase.dart';
import 'package:hero_mart/src/features/language/domain/usecases/sync_language_usecase.dart';
import 'package:hero_mart/src/features/language/presentation/cubit/localization_cubit.dart';
import 'package:intl/intl.dart' show Intl;

/// Answers each sync with the next queued reply (success once empty).
class _Repository implements LangRepository {
  final List<Either<Failure, Unit>> replies = [];
  final List<String> synced = [];

  @override
  Future<Either<Failure, String>> getSavedLang() async => const Right('en');

  @override
  Future<Either<Failure, Unit>> changeLang({required String langCode}) async =>
      const Right(unit);

  @override
  Future<Either<Failure, Unit>> syncLanguage({required String langCode}) async {
    synced.add(langCode);
    return replies.isEmpty ? const Right(unit) : replies.removeAt(0);
  }
}

LocalizationCubit _cubit(_Repository repository) => LocalizationCubit(
  getSavedLang: GetSavedLangUseCase(repository),
  changeLang: ChangeLangUseCase(repository),
  syncLanguage: SyncLanguageUseCase(repository),
);

void main() {
  test('a sync lost to the network is sent again on reconnect, once', () async {
    final repository = _Repository()
      ..replies.addAll([const Left(NetworkFailure()), const Right(unit)]);
    final cubit = _cubit(repository);
    addTearDown(cubit.close);

    await cubit.syncToServer();
    await cubit.onReconnected();
    await cubit.onReconnected();

    expect(repository.synced, ['en', 'en']);
  });

  test('nothing is owed after a refused sync, nor before any', () async {
    final repository = _Repository()
      ..replies.add(const Left(ServerFailure('refused', statusCode: 400)));
    final cubit = _cubit(repository);
    addTearDown(cubit.close);

    await cubit.onReconnected();
    await cubit.syncToServer();
    await cubit.onReconnected();

    expect(repository.synced, ['en']);
  });

  // B1: the app root set the restored locale before the cubit exists; a
  // request made before the launch restore ends must not go out as `en`.
  test('creating the cubit keeps the locale the app root set', () {
    final previous = Intl.defaultLocale;
    addTearDown(() => Intl.defaultLocale = previous);
    Intl.defaultLocale = 'ar';

    final cubit = _cubit(_Repository());
    addTearDown(cubit.close);

    expect(Intl.defaultLocale, 'ar');
  });
}
