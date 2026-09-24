import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/order_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/orders_repository.dart';

/// `GET /v1/orders/{id}` (tracking, invoice, review).
class GetOrderUseCase implements UseCase<OrderEntity, GetOrderParams> {
  const GetOrderUseCase(this._repository);
  final OrdersRepository _repository;

  @override
  Future<Either<Failure, OrderEntity>> call(GetOrderParams params) {
    if (params.orderId.isEmpty) {
      return Future.value(const Left(ValidationFailure('order id')));
    }
    return _repository.getOrder(params.orderId);
  }
}

class GetOrderParams extends Equatable {
  const GetOrderParams(this.orderId);

  final String orderId;

  @override
  List<Object?> get props => [orderId];
}
