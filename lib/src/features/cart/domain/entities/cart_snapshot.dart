import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/cart_entity.dart';
import '../../../../core/error/failures.dart';

/// Which cart operation a transient [CartSnapshot.failure] belongs to.
enum CartAction { none, sync, fetch, addItems, clear, coupon, loyalty, express }

/// What the cart repository streams: the server cart with the pending local
/// changes projected on top, plus the sync flags the UI shows.
class CartSnapshot extends Equatable {
  const CartSnapshot({
    this.cart = CartEntity.empty,
    this.isRestored = false,
    this.isSyncing = false,
    this.hasPendingChanges = false,
    this.isUnsynced = false,
    this.failure,
    this.failedAction = CartAction.none,
    this.revision = 0,
  });

  /// Server cart + pending changes. Discounts and delivery fee are the
  /// server's last word; only line quantities, `itemCount` and the subtotal
  /// move optimistically (see [hasPendingChanges]).
  final CartEntity cart;

  /// `true` once the mirror was read (or the first server reply arrived), so
  /// the UI can tell "no cart yet" from "empty cart".
  final bool isRestored;

  /// A request is in flight.
  final bool isSyncing;

  /// Local changes not confirmed by the server yet: the totals may be stale.
  final bool hasPendingChanges;

  /// The last sync attempt failed on transport; the changes are kept and
  /// retried.
  final bool isUnsynced;

  /// The most recent failed operation, cleared on the next snapshot.
  final Failure? failure;
  final CartAction failedAction;

  /// Bumps on every emission so two equal-looking failures still reach
  /// listeners.
  final int revision;

  /// Same state as [other] apart from [revision]: the repository skips an
  /// emission that would only bump the counter.
  bool sameStateAs(CartSnapshot other) =>
      cart == other.cart &&
      isRestored == other.isRestored &&
      isSyncing == other.isSyncing &&
      hasPendingChanges == other.hasPendingChanges &&
      isUnsynced == other.isUnsynced &&
      failure == other.failure &&
      failedAction == other.failedAction;

  @override
  List<Object?> get props => [
    // The revision differs on every emission, so it goes first: Equatable
    // stops at the first unequal prop.
    revision,
    cart,
    isRestored,
    isSyncing,
    hasPendingChanges,
    isUnsynced,
    failure,
    failedAction,
  ];
}
