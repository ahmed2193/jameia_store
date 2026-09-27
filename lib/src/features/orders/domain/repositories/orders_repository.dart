import 'package:dartz/dartz.dart';

import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/domain/entities/order_entity.dart';
import '../../../../core/error/failures.dart';
import '../entities/cancel_order_request.dart';
import '../entities/orders_page.dart';
import '../entities/product_review_request.dart';

/// Customer orders (`/v1/orders*`) and product reviews (`POST /v1/reviews`).
/// A `watch…` read gives the copy saved on the device first (offline too),
/// then the server's (skipped while the copy is fresh, unless
/// `forceRefresh`); failures arrive on the error channel.
abstract class OrdersRepository {
  /// `GET /v1/orders?page=1&limit`.
  Stream<DataSnapshot<OrdersPage>> watchFirstPage({
    required int limit,
    bool forceRefresh = false,
  });

  /// `GET /v1/orders?page&limit` — a later page, from the server only.
  Future<Either<Failure, OrdersPage>> getOrders({
    required int page,
    required int limit,
  });

  /// `GET /v1/orders/{id}` — the copy is never fresh (an order moves): it
  /// shows while the server answers, or instead of it offline.
  Stream<DataSnapshot<OrderEntity>> watchOrder(
    String orderId, {
    bool forceRefresh = false,
  });

  /// `GET /v1/orders/{id}` from the server only.
  Future<Either<Failure, OrderEntity>> getOrder(String orderId);

  /// The cancelled order comes back (and replaces the order's device copy).
  Future<Either<Failure, OrderEntity>> cancelOrder(CancelOrderRequest request);

  Future<Either<Failure, Unit>> submitReview(ProductReviewRequest request);
}
