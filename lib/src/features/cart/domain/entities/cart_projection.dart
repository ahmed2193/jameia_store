import '../../../../core/domain/entities/cart_entity.dart';
import '../../../../core/domain/entities/cart_line_entity.dart';
import '../../../../core/domain/entities/cart_line_ref.dart';
import 'cart_pending_change.dart';

/// Lays the pending local changes over the server cart so the UI shows what
/// the customer just did before the server confirms it.
extension CartProjection on CartEntity {
  /// Lines get their target quantity (a `0` target drops the line, a line
  /// the server does not know yet is drawn from the change's product
  /// snapshot at its list price), `itemCount` and `totals.subtotal` are
  /// re-summed; every discount stays the server's.
  CartEntity project(Map<CartLineRef, CartPendingChange> pending) {
    if (pending.isEmpty) return this;
    final projected = <CartLineEntity>[];
    final seen = <CartLineRef>{};
    for (final line in lines) {
      final change = pending[line.ref];
      if (change == null) {
        projected.add(line);
        continue;
      }
      seen.add(line.ref);
      final target = change.targetQuantity(line.quantity);
      if (target > 0) projected.add(line.withQuantity(target));
    }
    for (final change in pending.values) {
      if (seen.contains(change.ref)) continue;
      final product = change.product;
      final target = change.targetQuantity(0);
      if (product == null || target <= 0) continue;
      projected.add(
        CartLineEntity(
          key: '',
          product: product,
          quantity: target,
          unitPriceFils: product.priceFils,
          compareAtFils: product.compareAtFils,
          lineTotalFils: product.priceFils * target,
          variantId: change.ref.variantId,
        ),
      );
    }
    var itemCount = 0;
    var subtotal = 0;
    for (final line in projected) {
      itemCount += line.quantity;
      subtotal += line.lineTotalFils;
    }
    return copyWith(
      itemCount: itemCount,
      lines: projected,
      totals: totals.withSubtotal(subtotal),
    );
  }
}
