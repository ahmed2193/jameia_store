import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/order_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/cancel_order_request.dart';
import '../repositories/orders_repository.dart';

/// Cancels with one of the API's reasons; the note stays within 256
/// characters.
class CancelOrderUseCase implements UseCase<OrderEntity, CancelOrderParams> {
  const CancelOrderUseCase(this._repository);
  final OrdersRepository _repository;

  @override
  Future<Either<Failure, OrderEntity>> call(CancelOrderParams params) {
    if (!params.request.isValid) {
      return Future.value(const Left(ValidationFailure('cancel request')));
    }
    return _repository.cancelOrder(params.request);
  }
}

class CancelOrderParams extends Equatable {
  const CancelOrderParams(this.request);

  final CancelOrderRequest request;

  @override
  List<Object?> get props => [request];
}
