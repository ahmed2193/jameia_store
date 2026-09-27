import 'package:equatable/equatable.dart';

/// One picture of the order-summary strip: a paid line (its `CartLineRef`
/// as [id]) or a free gift (`'gift:<key>'`).
class CheckoutThumb extends Equatable {
  const CheckoutThumb({
    required this.id,
    required this.imageUrl,
    required this.quantity,
    this.isGift = false,
    this.hasIssue = false,
  });

  /// Stable per line, so a slot keeps its picture across re-prices.
  final Object id;
  final String imageUrl;
  final int quantity;
  final bool isGift;

  /// The line carries a server issue (out of stock, unavailable, reduced).
  final bool hasIssue;

  @override
  List<Object?> get props => [id, imageUrl, quantity, isGift, hasIssue];
}
