import 'package:dartz/dartz.dart';

import '../../../../core/domain/entities/auth_customer_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/account_repository.dart';

/// The live customer record (`GET /v1/account/me`).
class GetProfileUseCase implements UseCase<AuthCustomerEntity, NoParams> {
  const GetProfileUseCase(this._repository);

  final AccountRepository _repository;

  @override
  Future<Either<Failure, AuthCustomerEntity>> call(NoParams params) =>
      _repository.getProfile();
}
