import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/lang_repository.dart';

class ChangeLangParams extends Equatable {
  const ChangeLangParams(this.langCode);

  /// `en` / `ar`.
  final String langCode;

  @override
  List<Object?> get props => [langCode];
}

/// Persist the chosen language on the device.
class ChangeLangUseCase implements UseCase<Unit, ChangeLangParams> {
  const ChangeLangUseCase(this._repository);

  final LangRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(ChangeLangParams params) =>
      _repository.changeLang(langCode: params.langCode);
}
