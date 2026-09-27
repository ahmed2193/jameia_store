import '../../../../core/domain/entities/order_status.dart';
import 'checkout_cart_facts.dart';
import 'checkout_store_rules.dart';

/// The one rule for switching the payment method on the customer's behalf
/// (the API pays with one method in full). Each returns the method to switch
/// to, or `null` to leave the choice alone; the page announces every switch.
abstract final class CheckoutPaymentChoice {
  /// The store rules arrived (or the wallet changed): a draft still on cash
  /// on delivery moves to the wallet when the store turned cash off or
  /// prefers the wallet, and the customer's wallet covers the total.
  static OrderPaymentMethod? onRules({
    required CheckoutStoreRules rules,
    required OrderPaymentMethod current,
    required CheckoutCartFacts cart,
  }) {
    if (current != OrderPaymentMethod.cod) return null;
    final prefersWallet =
        !rules.codEnabled ||
        rules.defaultPaymentMethod == OrderPaymentMethod.wallet;
    // A guest has no wallet to move to.
    if (!prefersWallet || cart.walletFils == null) return null;
    return cart.walletCovers ? OrderPaymentMethod.wallet : null;
  }

  /// The total changed: a wallet that no longer covers it falls back to cash
  /// on delivery when the store takes cash; otherwise the choice stays and
  /// `CheckoutBlockReason.payment` blocks the order.
  static OrderPaymentMethod? onTotal({
    required CheckoutStoreRules rules,
    required OrderPaymentMethod current,
    required CheckoutCartFacts cart,
  }) =>
      current == OrderPaymentMethod.wallet &&
          !cart.walletCovers &&
          rules.codEnabled
      ? OrderPaymentMethod.cod
      : null;
}
