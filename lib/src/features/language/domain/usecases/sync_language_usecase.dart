import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/lang_repository.dart';

class SyncLanguageParams extends Equatable {
  const SyncLanguageParams(this.langCode);

  /// `en` / `ar`.
  final String langCode;

  @override
  List<Object?> get props => [langCode];
}

/// Mirror the device language onto the customer profile (no-op while signed
/// out). Best effort: callers log a failure, they never block the UI on it.
class SyncLanguageUseCase implements UseCase<Unit, SyncLanguageParams> {
  const SyncLanguageUseCase(this._repository);

  final LangRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(SyncLanguageParams params) =>
      _repository.syncLanguage(langCode: params.langCode);
}
