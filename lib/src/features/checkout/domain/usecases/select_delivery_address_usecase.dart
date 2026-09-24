import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/delivery_selection_entity.dart';
import '../repositories/checkout_repository.dart';

/// `POST /v1/delivery/select-address`.
class SelectDeliveryAddressUseCase
    implements UseCase<DeliverySelectionEntity, SelectDeliveryAddressParams> {
  const SelectDeliveryAddressUseCase(this._repository);
  final CheckoutRepository _repository;

  @override
  Future<Either<Failure, DeliverySelectionEntity>> call(
    SelectDeliveryAddressParams params,
  ) {
    if (params.addressId.isEmpty) {
      return Future.value(const Left(ValidationFailure('address id')));
    }
    return _repository.selectDeliveryAddress(params.addressId);
  }
}

class SelectDeliveryAddressParams extends Equatable {
  const SelectDeliveryAddressParams(this.addressId);

  final String addressId;

  @override
  List<Object?> get props => [addressId];
}
