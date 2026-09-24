import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/auth_customer_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class SaveCachedCustomerParams extends Equatable {
  const SaveCachedCustomerParams(this.customer);

  final AuthCustomerEntity customer;

  @override
  List<Object?> get props => [customer];
}

/// Keeps the device copy of the signed-in customer in step with the session.
class SaveCachedCustomerUseCase
    implements UseCase<Unit, SaveCachedCustomerParams> {
  const SaveCachedCustomerUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(SaveCachedCustomerParams params) =>
      _repository.saveCachedCustomer(params.customer);
}
