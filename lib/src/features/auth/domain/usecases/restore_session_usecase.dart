import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/domain/entities/auth_customer_entity.dart';
import '../repositories/auth_repository.dart';

/// Launch-time restore: `null` when signed out, else the validated customer.
class RestoreSessionUseCase implements UseCase<AuthCustomerEntity?, NoParams> {
  const RestoreSessionUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, AuthCustomerEntity?>> call(NoParams params) =>
      _repository.restoreSession();
}
