import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/order.dart';
import '../entities/order_tracking_view.dart';
import '../entities/orders_view.dart';
import '../entities/refund_detail.dart';

/// Read/write boundary for the order lifecycle. Offline, every method resolves
/// from the in-memory catalogue (mapped to framework-free entities); they still
/// return `Either<Failure, T>` so the presentation layer handles failure
/// uniformly.
abstract class OrdersRepository {
  /// Bucketed order list (active / history) for the orders screen.
  Future<Either<Failure, OrdersView>> getOrders();

  /// One order + the default delivery address for the tracking / map screens.
  Future<Either<Failure, OrderTrackingView>> getOrderTracking(String orderId);

  /// One order for the e-invoice screen ([orderId] null → most recent order).
  Future<Either<Failure, OrderEntity>> getInvoice(String? orderId);

  /// One order for the review screen.
  Future<Either<Failure, OrderEntity>> getReviewOrder(String orderId);

  /// The order the refund form targets (the most recent order).
  Future<Either<Failure, OrderEntity>> getRefundFormOrder();

  /// Derived refund progress / breakdown for the refund-detail screen.
  Future<Either<Failure, RefundDetail>> getRefundDetail(String orderId);

  /// Submit an order review (offline: accepted no-op with a simulated latency).
  Future<Either<Failure, bool>> submitReview({
    required String orderId,
    required int stars,
    required Set<String> likedTags,
    required Set<String> likedProducts,
    required int photoCount,
  });

  /// Submit a refund request (offline: accepted no-op).
  Future<Either<Failure, bool>> submitRefund({
    required String orderId,
    String? reason,
    required Map<int, int> selectedQty,
    required String description,
    required int photoCount,
    required double amount,
  });

  /// Cancel a user-placed order (offline: accepted no-op — the in-memory
  /// catalogue has no cancel mutation, so local state is unchanged on reload).
  Future<Either<Failure, bool>> cancelOrder({
    required String orderId,
    String? reason,
  });
}
