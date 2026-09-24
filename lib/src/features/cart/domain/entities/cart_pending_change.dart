import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/cart_line_ref.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';

/// A quantity change the customer made that the server has not confirmed
/// yet. Keyed by [ref]; taps on the same line coalesce into one change.
///
/// Two shapes: a relative [delta] (`+1` / `-1` taps, safe to replay on a
/// cart the server changed meanwhile, e.g. after a sign-in merge) or an
/// [absolute] target (remove line = `0`), which wins over any server value.
class CartPendingChange extends Equatable {
  const CartPendingChange({
    required this.ref,
    this.product,
    this.delta = 0,
    this.absolute,
    this.version = 0,
  });

  final CartLineRef ref;

  /// Catalogue card for a line that does not exist on the server yet, so
  /// the cart page can draw it before the reply. `null` for "reorder" rows.
  final CatalogProductEntity? product;
  final int delta;
  final int? absolute;

  /// Bumps on every merge; a reply "rebases" only the version it was sent
  /// with (see `CartRepositoryImpl`).
  final int version;

  /// Quantity the server should end up with, given the [serverQuantity] it
  /// has for this line now (`0` when the line does not exist there).
  int targetQuantity(int serverQuantity) {
    final absolute = this.absolute;
    if (absolute != null) return absolute < 0 ? 0 : absolute;
    final target = serverQuantity + delta;
    return target < 0 ? 0 : target;
  }

  /// Whether the change still asks for something.
  bool get isNoOp => absolute == null && delta == 0;

  CartPendingChange plus(int delta, {CatalogProductEntity? product}) {
    final absolute = this.absolute;
    return CartPendingChange(
      ref: ref,
      product: product ?? this.product,
      delta: absolute == null ? this.delta + delta : 0,
      absolute: absolute == null ? null : absolute + delta,
      version: version + 1,
    );
  }

  CartPendingChange setTo(int quantity, {CatalogProductEntity? product}) =>
      CartPendingChange(
        ref: ref,
        product: product ?? this.product,
        absolute: quantity,
        version: version + 1,
      );

  /// After the server confirmed [appliedDelta] of a relative change, the
  /// remainder still owed (taps that arrived while the request was in
  /// flight). An absolute change is re-sent whole.
  CartPendingChange? afterApplied(int appliedDelta) {
    if (absolute != null) return this;
    final remaining = delta - appliedDelta;
    if (remaining == 0) return null;
    return CartPendingChange(
      ref: ref,
      product: product,
      delta: remaining,
      version: version,
    );
  }

  @override
  List<Object?> get props => [ref, product, delta, absolute, version];
}
