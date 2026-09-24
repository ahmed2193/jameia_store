import 'package:equatable/equatable.dart';

/// One customer review of a product.
class ProductReview extends Equatable {
  const ProductReview({
    required this.id,
    required this.rating,
    required this.createdAt,
    this.title = '',
    this.body = '',
    this.customerName = '',
  });

  final String id;

  /// 1..5.
  final int rating;
  final DateTime createdAt;
  final String title;
  final String body;
  final String customerName;

  @override
  List<Object?> get props => [id, rating, createdAt, title, body, customerName];
}

/// The reviews loaded so far (`GET /v1/products/:slug/reviews`, pages merged in
/// order) with the product's rating summary.
class ProductReviews extends Equatable {
  const ProductReviews({
    required this.reviews,
    required this.page,
    required this.hasMore,
    required this.total,
    this.ratingAverage = 0,
    this.ratingCount = 0,
  });

  static const ProductReviews empty = ProductReviews(
    reviews: <ProductReview>[],
    page: 0,
    hasMore: false,
    total: 0,
  );

  final List<ProductReview> reviews;

  /// Last page merged in (1-based); `0` before the first load.
  final int page;
  final bool hasMore;
  final int total;
  final double ratingAverage;
  final int ratingCount;

  bool get isEmpty => reviews.isEmpty;

  /// Appends [next] (a later page), dropping reviews already shown.
  ProductReviews merge(ProductReviews next) {
    final known = {for (final review in reviews) review.id};
    return ProductReviews(
      reviews: [
        ...reviews,
        ...next.reviews.where((review) => !known.contains(review.id)),
      ],
      page: next.page,
      hasMore: next.hasMore,
      total: next.total,
      ratingAverage: next.ratingAverage,
      ratingCount: next.ratingCount,
    );
  }

  @override
  List<Object?> get props => [
    reviews,
    page,
    hasMore,
    total,
    ratingAverage,
    ratingCount,
  ];
}
