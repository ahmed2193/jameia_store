import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/lang_repository.dart';

/// The language the user chose earlier (`''` when none).
class GetSavedLangUseCase implements UseCase<String, NoParams> {
  const GetSavedLangUseCase(this._repository);

  final LangRepository _repository;

  @override
  Future<Either<Failure, String>> call(NoParams params) =>
      _repository.getSavedLang();
}
