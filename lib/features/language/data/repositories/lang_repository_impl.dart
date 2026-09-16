import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/repositories/lang_repository.dart';
import '../datasources/lang_local_data_source.dart';

/// Local-only implementation — persists the choice and always succeeds.
class LangRepositoryImpl implements LangRepository {
  final LangLocalDataSource localDataSource;
  const LangRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, String>> getSavedLang() async {
    try {
      return Right(await localDataSource.getSavedLang());
    } catch (_) {
      return const Right(''); // unreadable prefs → let the caller apply default
    }
  }

  @override
  Future<Either<Failure, void>> changeLang({required String langCode}) async {
    try {
      await localDataSource.changeLang(langCode);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to persist language: $e'));
    }
  }
}
