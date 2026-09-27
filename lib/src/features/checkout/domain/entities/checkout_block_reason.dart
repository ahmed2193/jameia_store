import '../../../../core/domain/entities/cart_entity.dart';
import '../../../../core/domain/entities/order_status.dart';
import 'checkout_cart_facts.dart';
import 'checkout_draft.dart';
import 'checkout_store_rules.dart';

/// Why the order cannot be placed right now; the one owner of every content
/// rule of the checkout (the cubit keeps only its in-flight flags). The
/// first reason in declaration order wins.
enum CheckoutBlockReason {
  /// The store is closed for maintenance.
  maintenance,

  /// No address / branch chosen, or the server has not resolved it yet.
  destination,

  /// Scheduled delivery without a window.
  slot,

  /// The note is longer than `POST /v1/orders` accepts.
  notesTooLong,

  /// Local cart changes could not reach the server.
  offline,

  /// Nothing to order.
  empty,

  /// A line is out of stock or unavailable.
  lineIssue,

  /// Below the minimum order.
  minOrder,

  /// The serving branch is closed.
  branchClosed,

  /// The branch has no capacity.
  capacity,

  /// No usable payment method: an unknown one, cash on delivery while the
  /// store turned it off, or a wallet that does not cover the total.
  payment;

  /// The first reason the order cannot go, or `null` when it can.
  static CheckoutBlockReason? resolve({
    required CheckoutDraft draft,
    required bool hasSelection,
    required CheckoutStoreRules rules,
    required CheckoutCartFacts cart,
  }) {
    if (rules.maintenance) return maintenance;
    if (!draft.hasDestination || !hasSelection) return destination;
    if (draft.needsSlot) return slot;
    if (draft.notesTooLong) return notesTooLong;
    if (cart.unsynced) return offline;
    final cartReason = switch (cart.block) {
      null => null,
      CartCheckoutBlock.empty => empty,
      CartCheckoutBlock.lineIssue => lineIssue,
      CartCheckoutBlock.belowMinOrder => minOrder,
      CartCheckoutBlock.branchClosed => branchClosed,
      CartCheckoutBlock.noCapacity => capacity,
    };
    if (cartReason != null) return cartReason;
    return switch (draft.paymentMethod) {
      OrderPaymentMethod.cod => rules.codEnabled ? null : payment,
      OrderPaymentMethod.wallet => cart.walletCovers ? null : payment,
      OrderPaymentMethod.other => payment,
    };
  }
}
