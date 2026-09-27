import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../../../core/data/mappers/order_mapper.dart';
import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/data/repositories/cached_repository_mixin.dart';
import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/domain/entities/order_entity.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/cancel_order_request.dart';
import '../../domain/entities/orders_page.dart';
import '../../domain/entities/product_review_request.dart';
import '../../domain/repositories/orders_repository.dart';
import '../datasources/orders_cache_data_source.dart';
import '../datasources/orders_remote_data_source.dart';
import '../mappers/orders_mapper.dart';

class OrdersRepositoryImpl
    with BaseRepositoryMixin, CachedRepositoryMixin
    implements OrdersRepository {
  const OrdersRepositoryImpl(this._remote, {required this._cache});

  final OrdersRemoteDataSource _remote;
  final OrdersCacheDataSource _cache;

  static const int _firstPage = 1;

  @override
  Stream<DataSnapshot<OrdersPage>> watchFirstPage({
    required int limit,
    bool forceRefresh = false,
  }) => cachedRead(
    cache: _cache.firstPage(limit: limit),
    fetch: () => _remote.getOrders(page: _firstPage, limit: limit),
    toEntity: (model) => model.toEntity(),
    forceRefresh: forceRefresh,
  );

  @override
  Future<Either<Failure, OrdersPage>> getOrders({
    required int page,
    required int limit,
  }) => execute(
    () async =>
        (await _remote.getOrders(page: page, limit: limit)).model.toEntity(),
  );

  @override
  Stream<DataSnapshot<OrderEntity>> watchOrder(
    String orderId, {
    bool forceRefresh = false,
  }) => cachedRead(
    cache: _cache.order(orderId),
    fetch: () => _remote.getOrder(orderId),
    toEntity: (model) => model.toEntity(),
    forceRefresh: forceRefresh,
  );

  @override
  Future<Either<Failure, OrderEntity>> getOrder(String orderId) =>
      execute(() async => (await _remote.getOrder(orderId)).model.toEntity());

  /// The cancelled order replaces its saved copy; the saved lists, which
  /// still show it running, are forgotten.
  @override
  Future<Either<Failure, OrderEntity>> cancelOrder(CancelOrderRequest request) {
    // Taken before the request: a reply for a customer who signed out
    // meanwhile is not kept.
    final copy = _cache.order(request.orderId);
    return execute(() async {
      final reply = await _remote.cancelOrder(
        request.orderId,
        request.toBody(),
      );
      keepReply(copy, reply.raw);
      unawaited(_cache.forgetPages());
      return reply.model.toEntity();
    });
  }

  @override
  Future<Either<Failure, Unit>> submitReview(ProductReviewRequest request) =>
      execute(() async {
        await _remote.submitReview(request.toBody());
        return unit;
      });
}
