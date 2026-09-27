import '../../../../core/domain/entities/cart_entity.dart';

/// Tells when the server let go of the customer's coupon on its own (a
/// re-price after an address change, a basket that no longer qualifies), so
/// the page can say so instead of letting the saving vanish silently.
abstract final class CheckoutCouponDrop {
  /// The dropped code, or `null`: the cart had a coupon before and either
  /// has none now or keeps the same code at a zero saving after it saved
  /// something. A different code is the customer's own change.
  static String? droppedCode(CartEntity before, CartEntity after) {
    final was = before.coupon;
    if (was == null) return null;
    final now = after.coupon;
    if (now == null) return was.code;
    if (now.code == was.code && was.discountFils > 0 && now.discountFils == 0) {
      return was.code;
    }
    return null;
  }
}
