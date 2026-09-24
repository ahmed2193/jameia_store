import 'package:dartz/dartz.dart';

import '../../../../core/domain/entities/order_entity.dart';
import '../../../../core/error/failures.dart';
import '../entities/cancel_order_request.dart';
import '../entities/orders_page.dart';
import '../entities/product_review_request.dart';

/// Customer orders (`/v1/orders*`) and product reviews (`POST /v1/reviews`).
abstract class OrdersRepository {
  Future<Either<Failure, OrdersPage>> getOrders({
    required int page,
    required int limit,
  });

  Future<Either<Failure, OrderEntity>> getOrder(String orderId);

  /// The cancelled order comes back.
  Future<Either<Failure, OrderEntity>> cancelOrder(CancelOrderRequest request);

  Future<Either<Failure, Unit>> submitReview(ProductReviewRequest request);
}
