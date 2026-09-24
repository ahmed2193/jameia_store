import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/delivery_selection_entity.dart';
import '../repositories/checkout_repository.dart';

/// `POST /v1/delivery/select-branch`.
class SelectPickupBranchUseCase
    implements UseCase<DeliverySelectionEntity, SelectPickupBranchParams> {
  const SelectPickupBranchUseCase(this._repository);
  final CheckoutRepository _repository;

  @override
  Future<Either<Failure, DeliverySelectionEntity>> call(
    SelectPickupBranchParams params,
  ) {
    if (params.branchId.isEmpty) {
      return Future.value(const Left(ValidationFailure('branch id')));
    }
    return _repository.selectPickupBranch(params.branchId);
  }
}

class SelectPickupBranchParams extends Equatable {
  const SelectPickupBranchParams(this.branchId);

  final String branchId;

  @override
  List<Object?> get props => [branchId];
}
