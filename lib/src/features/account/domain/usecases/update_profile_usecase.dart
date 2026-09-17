import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/auth_customer_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/profile_update.dart';
import '../repositories/account_repository.dart';

class UpdateProfileParams extends Equatable {
  const UpdateProfileParams(this.update);

  final ProfileUpdate update;

  @override
  List<Object?> get props => [update];
}

/// `PATCH /v1/account/profile`. An empty update short-circuits to a failure so
/// the UI never fires a no-op request.
class UpdateProfileUseCase
    implements UseCase<AuthCustomerEntity, UpdateProfileParams> {
  const UpdateProfileUseCase(this._repository);

  static const String nothingToSaveMessage = 'Nothing to save';

  final AccountRepository _repository;

  @override
  Future<Either<Failure, AuthCustomerEntity>> call(
    UpdateProfileParams params,
  ) async {
    if (params.update.isEmpty) {
      return const Left(UnexpectedFailure(nothingToSaveMessage));
    }
    return _repository.updateProfile(params.update);
  }
}
