import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/order_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/checkout_draft.dart';
import '../repositories/checkout_repository.dart';

/// `POST /v1/orders` once the draft is complete (destination chosen, a slot
/// when scheduled, notes within the limit).
class PlaceOrderUseCase implements UseCase<OrderEntity, PlaceOrderParams> {
  const PlaceOrderUseCase(this._repository);
  final CheckoutRepository _repository;

  @override
  Future<Either<Failure, OrderEntity>> call(PlaceOrderParams params) {
    if (!params.draft.isComplete) {
      return Future.value(const Left(ValidationFailure('checkout draft')));
    }
    return _repository.placeOrder(params.draft);
  }
}

class PlaceOrderParams extends Equatable {
  const PlaceOrderParams(this.draft);

  final CheckoutDraft draft;

  @override
  List<Object?> get props => [draft];
}
