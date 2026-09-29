import 'package:flutter/foundation.dart';

/// `extra` of [Routes.orderReview] when the customer already tapped a star
/// on the order page: the review opens with every product at [rating]
/// (1–5), ready to send or adjust. Every other entry passes the order id (a
/// `String`).
@immutable
class OrderReviewArgs {
  const OrderReviewArgs({required this.orderId, required this.rating});

  final String orderId;
  final int rating;
}
