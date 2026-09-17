import 'package:dartz/dartz.dart';

import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/lang_repository.dart';
import '../datasources/lang_local_data_source.dart';
import '../datasources/lang_remote_data_source.dart';

class LangRepositoryImpl with BaseRepositoryMixin implements LangRepository {
  const LangRepositoryImpl({required this._local, required this._remote});

  final LangLocalDataSource _local;
  final LangRemoteDataSource _remote;

  @override
  Future<Either<Failure, String>> getSavedLang() =>
      execute(_local.getSavedLang);

  @override
  Future<Either<Failure, Unit>> changeLang({required String langCode}) =>
      execute(() async {
        await _local.changeLang(langCode);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> syncLanguage({required String langCode}) =>
      execute(() async {
        if (!await _local.isSignedIn()) return unit;
        await _remote.syncLanguage(langCode);
        return unit;
      });
}
