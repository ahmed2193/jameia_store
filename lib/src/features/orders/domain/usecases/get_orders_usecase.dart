import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/orders_page.dart';
import '../repositories/orders_repository.dart';

/// One page of the customer's orders (newest first).
class GetOrdersUseCase implements UseCase<OrdersPage, GetOrdersParams> {
  const GetOrdersUseCase(this._repository);
  final OrdersRepository _repository;

  @override
  Future<Either<Failure, OrdersPage>> call(GetOrdersParams params) =>
      _repository.getOrders(
        page: params.page < GetOrdersParams.firstPage
            ? GetOrdersParams.firstPage
            : params.page,
        limit: params.limit.clamp(
          GetOrdersParams.minLimit,
          GetOrdersParams.maxLimit,
        ),
      );
}

class GetOrdersParams extends Equatable {
  const GetOrdersParams({this.page = firstPage, this.limit = defaultLimit});

  static const int firstPage = 1;
  static const int minLimit = 1;
  static const int maxLimit = 100;
  static const int defaultLimit = 20;

  final int page;
  final int limit;

  @override
  List<Object?> get props => [page, limit];
}
