import '../../../cart/presentation/cubit/cart_state.dart';
import '../../domain/entities/checkout_cart_facts.dart';
import '../../domain/entities/checkout_eta.dart';

/// The app-global cart state in the checkout domain's terms: the one
/// adapter the page, the place-order bar and the ETA widgets read the cart
/// through (the cart's state class belongs to another feature, so the
/// checkout domain only ever sees these values).
extension CheckoutCartFactsOf on CartState {
  /// What the order needs from the cart and the session
  /// (`CheckoutBlockReason.resolve`, `CheckoutPaymentChoice`,
  /// `CheckoutCubit.placeOrder`). [walletFils] is the signed-in customer's
  /// balance, `null` for a guest.
  CheckoutCartFacts checkoutFacts({required int? walletFils}) =>
      CheckoutCartFacts(
        block: cart.checkoutBlock,
        unsynced: isUnsynced,
        settled: !isUpdating && !isBusy,
        walletFils: walletFils,
        totalFils: cart.totals.totalFils,
      );

  /// What the delivery estimate needs from the cart (a record: equal carts
  /// rebuild nothing).
  CheckoutEtaCartFacts get etaFacts => (
    expressSelected: cart.expressSelected,
    expressEtaMinutes: cart.expressEtaMinutes,
    cartEtaMinutes: cart.totals.etaMinutes,
    branchOpen: cart.branchOpen,
    capacityAvailable: cart.capacityAvailable,
  );
}
