import 'package:dartz/dartz.dart';

import '../../../../core/domain/entities/auth_customer_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

/// The customer saved on this device by the last session, shown at launch
/// before `GET /v1/account/me` answers; `null` when there is none (or no
/// session is stored).
class GetCachedCustomerUseCase
    implements UseCase<AuthCustomerEntity?, NoParams> {
  const GetCachedCustomerUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, AuthCustomerEntity?>> call(NoParams params) =>
      _repository.getCachedCustomer();
}
