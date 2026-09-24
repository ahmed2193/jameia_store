import 'package:equatable/equatable.dart';

import 'product_review_request.dart';

/// Stars per product plus one comment, turned into one review request per
/// rated product.
class OrderReviewDraft extends Equatable {
  const OrderReviewDraft({
    this.ratings = const <String, int>{},
    this.comment = '',
    this.sent = const <String>{},
  });

  final Map<String, int> ratings;
  final String comment;

  /// Products whose review the server already accepted: their stars stay on
  /// screen, and a retry never sends them twice.
  final Set<String> sent;

  int ratingOf(String productId) => ratings[productId] ?? 0;
  bool isSent(String productId) => sent.contains(productId);
  bool get hasRating => ratings.entries.any(
    (entry) => entry.value > 0 && !sent.contains(entry.key),
  );
  bool get commentTooLong =>
      comment.length > ProductReviewRequest.maxBodyLength;
  bool get canSubmit => hasRating && !commentTooLong;

  OrderReviewDraft rate(String productId, int rating) => OrderReviewDraft(
    ratings: {...ratings, productId: rating},
    comment: comment,
    sent: sent,
  );

  OrderReviewDraft withComment(String comment) =>
      OrderReviewDraft(ratings: ratings, comment: comment, sent: sent);

  /// The server accepted [productId]'s review.
  OrderReviewDraft markSent(String productId) => OrderReviewDraft(
    ratings: ratings,
    comment: comment,
    sent: {...sent, productId},
  );

  List<ProductReviewRequest> toRequests(String orderId) => [
    for (final entry in ratings.entries)
      if (entry.value > 0 && !sent.contains(entry.key))
        ProductReviewRequest(
          productId: entry.key,
          orderId: orderId,
          rating: entry.value,
          body: comment.trim(),
        ),
  ];

  @override
  List<Object?> get props => [ratings, comment, sent];
}
