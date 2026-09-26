import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/settings_repository.dart';

/// Frees the space the app's downloaded images take on the device.
class ClearAppCacheUseCase implements UseCase<Unit, NoParams> {
  const ClearAppCacheUseCase(this._repository);

  final SettingsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) =>
      _repository.clearCache();
}
