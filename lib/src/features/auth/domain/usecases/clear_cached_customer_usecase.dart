import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

/// Removes the device copy of the customer when the session ends.
class ClearCachedCustomerUseCase implements UseCase<Unit, NoParams> {
  const ClearCachedCustomerUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) =>
      _repository.clearCachedCustomer();
}
