import 'package:equatable/equatable.dart';

/// `POST /v1/reviews` — one product of one order.
class ProductReviewRequest extends Equatable {
  const ProductReviewRequest({
    required this.productId,
    required this.orderId,
    required this.rating,
    this.title = '',
    this.body = '',
  });

  static const int minRating = 1;
  static const int maxRating = 5;
  static const int maxTitleLength = 120;
  static const int maxBodyLength = 2000;

  final String productId;
  final String orderId;
  final int rating;
  final String title;
  final String body;

  bool get isValid =>
      productId.isNotEmpty &&
      orderId.isNotEmpty &&
      rating >= minRating &&
      rating <= maxRating &&
      title.length <= maxTitleLength &&
      body.length <= maxBodyLength;

  @override
  List<Object?> get props => [productId, orderId, rating, title, body];
}
