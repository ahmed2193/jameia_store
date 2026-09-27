import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/cart_entity.dart';
import 'checkout_thumb.dart';

/// The order-summary strip as values: the first pictures (paid lines, then
/// gifts), the pieces in the basket and how many lines block the order.
/// Equal carts give equal strips, so the strip rebuilds only on a change.
class CheckoutThumbs extends Equatable {
  const CheckoutThumbs({
    this.slots = const <CheckoutThumb>[],
    this.totalPieces = 0,
    this.blockingCount = 0,
  });

  /// The strip never shows more pictures than this.
  static const int maxSlots = 5;

  static const String _giftPrefix = 'gift:';

  /// [max] (clamped to 1..[maxSlots]) is how many pictures fit.
  factory CheckoutThumbs.of(CartEntity cart, {required int max}) {
    final cap = max.clamp(1, maxSlots);
    final slots = <CheckoutThumb>[
      for (final line in cart.lines.take(cap))
        CheckoutThumb(
          id: line.ref,
          imageUrl: line.product.image,
          quantity: line.quantity,
          hasIssue: line.hasIssue,
        ),
    ];
    for (final gift in cart.offerLines) {
      if (slots.length >= cap) break;
      slots.add(
        CheckoutThumb(
          id: '$_giftPrefix${gift.key}',
          imageUrl: gift.product.image,
          quantity: gift.quantity,
          isGift: true,
        ),
      );
    }
    return CheckoutThumbs(
      slots: List<CheckoutThumb>.unmodifiable(slots),
      totalPieces: piecesOf(cart),
      blockingCount: blockingOf(cart),
    );
  }

  /// Σ paid quantities + Σ gift quantities ("N pcs") — for a caller that
  /// needs only the count.
  static int piecesOf(CartEntity cart) {
    var pieces = 0;
    for (final line in cart.lines) {
      pieces += line.quantity;
    }
    for (final gift in cart.offerLines) {
      pieces += gift.quantity;
    }
    return pieces;
  }

  /// The lines whose issue blocks the order (out of stock, unavailable) —
  /// for a caller that needs only the count.
  static int blockingOf(CartEntity cart) {
    var blocking = 0;
    for (final line in cart.lines) {
      if (line.blocksCheckout) blocking++;
    }
    return blocking;
  }

  final List<CheckoutThumb> slots;

  /// [piecesOf] the cart.
  final int totalPieces;

  /// [blockingOf] the cart: the "N items unavailable" banner counts these.
  final int blockingCount;

  @override
  List<Object?> get props => [slots, totalPieces, blockingCount];
}
