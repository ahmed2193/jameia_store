import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_tracking_view.dart';
import '../../domain/entities/orders_view.dart';
import '../../domain/entities/refund_detail.dart';
import '../../domain/repositories/orders_repository.dart';
import '../datasources/orders_local_data_source.dart';
import '../mappers/order_address_mapper.dart';
import '../mappers/order_mapper.dart';

/// Offline orders repository — reads the in-memory [OrdersLocalDataSource] DTOs,
/// maps them to framework-free entities, composes the feature view entities, and
/// wraps every result in `Either<Failure, T>` (mapping any read/lookup error to
/// [CacheFailure]).
class OrdersRepositoryImpl implements OrdersRepository {
  OrdersRepositoryImpl({required this.local});

  final OrdersLocalDataSource local;

  @override
  Future<Either<Failure, OrdersView>> getOrders() async {
    try {
      final all = local.orders();
      // Resolve each order's navigable shop id in the data layer so the order
      // card no longer reaches into the catalogue statically (B2).
      final entities = all
          .map((o) => o.toEntity(navShopId: local.navigableShopId(o)))
          .toList(growable: false);
      return Right(OrdersView(
        active: entities.where((o) => o.isActive).toList(growable: false),
        history: entities.where((o) => !o.isActive).toList(growable: false),
      ));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OrderTrackingView>> getOrderTracking(
    String orderId,
  ) async {
    try {
      return Right(OrderTrackingView(
        order: local.orderById(orderId).toEntity(),
        address: local.defaultAddress().toEntity(),
      ));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OrderEntity>> getInvoice(String? orderId) async {
    try {
      final order = orderId == null ? local.firstOrder() : local.orderById(orderId);
      return Right(order.toEntity());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OrderEntity>> getReviewOrder(String orderId) async {
    try {
      return Right(local.orderById(orderId).toEntity());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OrderEntity>> getRefundFormOrder() async {
    try {
      return Right(local.firstOrder().toEntity());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RefundDetail>> getRefundDetail(String orderId) async {
    try {
      return Right(local.refundDetail(orderId));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> submitReview({
    required String orderId,
    required int stars,
    required Set<String> likedTags,
    required Set<String> likedProducts,
    required int photoCount,
  }) async {
    try {
      await local.submitReview(
        orderId: orderId,
        stars: stars,
        likedTags: likedTags,
        likedProducts: likedProducts,
        photoCount: photoCount,
      );
      return const Right(true);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> submitRefund({
    required String orderId,
    String? reason,
    required Map<int, int> selectedQty,
    required String description,
    required int photoCount,
    required double amount,
  }) async {
    try {
      await local.submitRefund(
        orderId: orderId,
        reason: reason,
        selectedQty: selectedQty,
        description: description,
        photoCount: photoCount,
        amount: amount,
      );
      return const Right(true);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> cancelOrder({
    required String orderId,
    String? reason,
  }) async {
    try {
      await local.cancelOrder(orderId: orderId, reason: reason);
      return const Right(true);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
