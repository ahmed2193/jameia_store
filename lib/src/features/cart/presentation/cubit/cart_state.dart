import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/cart_entity.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/cart_snapshot.dart';

export '../../domain/entities/cart_snapshot.dart' show CartAction;

/// App-wide cart state: the projected cart (server + pending taps) and the
/// sync flags. Discounts and delivery fee are the server's; [isUpdating]
/// says they may lag the quantities the customer sees.
class CartState extends Equatable {
  const CartState({
    this.cart = CartEntity.empty,
    this.isRestored = false,
    this.isSyncing = false,
    this.hasPendingChanges = false,
    this.isUnsynced = false,
    this.busyAction = CartAction.none,
    this.failure,
    this.failedAction = CartAction.none,
    this.quantityByProduct = const <String, int>{},
    this.revision = 0,
  });

  final CartEntity cart;

  /// The device copy (or a first server reply) was read: an empty cart is a
  /// real empty cart, not "loading".
  final bool isRestored;
  final bool isSyncing;
  final bool hasPendingChanges;

  /// The last sync failed on transport; taps are kept and retried.
  final bool isUnsynced;

  /// A server-confirmed action (coupon, loyalty, express, clear, reorder,
  /// refresh, flush) in flight — its control is disabled meanwhile.
  final CartAction busyAction;

  /// Transient: set on the state that reports a failed action, cleared by
  /// the next [copyWith]. The page shows `failure.localizedMessage`.
  final Failure? failure;
  final CartAction failedAction;

  /// Product id → pieces, precomputed so tiles select one int.
  final Map<String, int> quantityByProduct;

  /// Bumps with every repository snapshot so equal-looking failures still
  /// reach listeners.
  final int revision;

  int get totalQty => cart.itemCount;
  bool get isEmpty => cart.isEmpty;
  double get subtotalKd => cart.totals.subtotalKd;
  bool get isBusy => busyAction != CartAction.none;

  /// Quantities moved ahead of the server: totals may be stale.
  bool get isUpdating => isSyncing || hasPendingChanges;
  bool get isSignedOut => failure is UnauthorizedFailure;

  int qtyOfProduct(String productId) => quantityByProduct[productId] ?? 0;

  CartState copyWith({
    CartEntity? cart,
    bool? isRestored,
    bool? isSyncing,
    bool? hasPendingChanges,
    bool? isUnsynced,
    CartAction? busyAction,
    Failure? failure,
    CartAction? failedAction,
    Map<String, int>? quantityByProduct,
    int? revision,
  }) => CartState(
    cart: cart ?? this.cart,
    isRestored: isRestored ?? this.isRestored,
    isSyncing: isSyncing ?? this.isSyncing,
    hasPendingChanges: hasPendingChanges ?? this.hasPendingChanges,
    isUnsynced: isUnsynced ?? this.isUnsynced,
    busyAction: busyAction ?? this.busyAction,
    failure: failure,
    failedAction: failedAction ?? CartAction.none,
    quantityByProduct: quantityByProduct ?? this.quantityByProduct,
    revision: revision ?? this.revision,
  );

  @override
  List<Object?> get props => [
    // The revision differs on every repository snapshot, so it goes first:
    // Equatable stops at the first unequal prop instead of walking the cart.
    // [quantityByProduct] is derived from [cart] and is left out on purpose.
    revision,
    cart,
    isRestored,
    isSyncing,
    hasPendingChanges,
    isUnsynced,
    busyAction,
    failure,
    failedAction,
  ];
}
