import 'package:dartz/dartz.dart';

import '../../../../core/data/mappers/order_mapper.dart';
import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/domain/entities/order_entity.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/cancel_order_request.dart';
import '../../domain/entities/orders_page.dart';
import '../../domain/entities/product_review_request.dart';
import '../../domain/repositories/orders_repository.dart';
import '../datasources/orders_remote_data_source.dart';
import '../mappers/orders_mapper.dart';

class OrdersRepositoryImpl
    with BaseRepositoryMixin
    implements OrdersRepository {
  const OrdersRepositoryImpl(this._remote);

  final OrdersRemoteDataSource _remote;

  @override
  Future<Either<Failure, OrdersPage>> getOrders({
    required int page,
    required int limit,
  }) => execute(
    () async => (await _remote.getOrders(page: page, limit: limit)).toEntity(),
  );

  @override
  Future<Either<Failure, OrderEntity>> getOrder(String orderId) =>
      execute(() async => (await _remote.getOrder(orderId)).toEntity());

  @override
  Future<Either<Failure, OrderEntity>> cancelOrder(
    CancelOrderRequest request,
  ) => execute(
    () async => (await _remote.cancelOrder(
      request.orderId,
      request.toBody(),
    )).toEntity(),
  );

  @override
  Future<Either<Failure, Unit>> submitReview(ProductReviewRequest request) =>
      execute(() async {
        await _remote.submitReview(request.toBody());
        return unit;
      });
}
