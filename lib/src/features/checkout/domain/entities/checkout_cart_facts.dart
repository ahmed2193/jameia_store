import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/cart_entity.dart';

/// What checkout needs to know about the app-global cart and the session to
/// decide whether the order can go, as plain values (the cart's state class
/// belongs to another feature's presentation layer).
class CheckoutCartFacts extends Equatable {
  const CheckoutCartFacts({
    this.block,
    this.unsynced = false,
    this.settled = true,
    this.walletFils,
    this.totalFils = 0,
  });

  /// Why the cart itself cannot be ordered (`CartEntity.checkoutBlock`).
  final CartCheckoutBlock? block;

  /// Local changes could not reach the server.
  final bool unsynced;

  /// No tap is on its way and no cart call is in flight
  /// (`!isUpdating && !isBusy`).
  final bool settled;

  /// The signed-in customer's wallet balance; `null` for a guest.
  final int? walletFils;

  /// The cart total the server priced.
  final int totalFils;

  /// The wallet pays the whole order (the API takes one method in full).
  bool get walletCovers => (walletFils ?? 0) >= totalFils;

  @override
  List<Object?> get props => [block, unsynced, settled, walletFils, totalFils];
}
