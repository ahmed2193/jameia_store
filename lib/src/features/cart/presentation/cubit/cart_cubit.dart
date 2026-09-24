import 'dart:async';
import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/cart_item_request.dart';
import '../../../../core/domain/entities/cart_line_entity.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/cart_snapshot.dart';
import '../../domain/usecases/add_cart_items_usecase.dart';
import '../../domain/usecases/adjust_cart_line_usecase.dart';
import '../../domain/usecases/apply_cart_coupon_usecase.dart';
import '../../domain/usecases/apply_cart_loyalty_usecase.dart';
import '../../domain/usecases/clear_cart_usecase.dart';
import '../../domain/usecases/fetch_cart_usecase.dart';
import '../../domain/usecases/flush_cart_usecase.dart';
import '../../domain/usecases/remove_cart_coupon_usecase.dart';
import '../../domain/usecases/remove_cart_line_usecase.dart';
import '../../domain/usecases/remove_cart_loyalty_usecase.dart';
import '../../domain/usecases/reset_cart_usecase.dart';
import '../../domain/usecases/restore_cart_usecase.dart';
import '../../domain/usecases/set_cart_express_usecase.dart';
import '../../domain/usecases/set_cart_line_quantity_usecase.dart';
import '../../domain/usecases/sync_cart_owner_usecase.dart';
import '../../domain/usecases/watch_cart_usecase.dart';
import 'cart_state.dart';

/// App-global cart. Taps apply at once (the repository mirrors them to the
/// server); server-confirmed actions run one at a time ([CartState.isBusy]).
///
/// Session-bound: the app root calls [onSignedIn] / [onSignedOut] /
/// [onGuestSession] from its `AuthSessionCubit` listener and
/// [onLocaleChanged] when the language flips (line names are localized by
/// the server).
class CartCubit extends Cubit<CartState> with SafeCubitMixin<CartState> {
  CartCubit({
    required this._watch,
    required this._restore,
    required this._syncOwner,
    required this._fetch,
    required this._flush,
    required this._adjustLine,
    required this._setLineQuantity,
    required this._removeLine,
    required this._addItems,
    required this._clear,
    required this._applyCoupon,
    required this._removeCoupon,
    required this._applyLoyalty,
    required this._removeLoyalty,
    required this._setExpress,
    required this._reset,
  }) : super(const CartState());

  final WatchCartUseCase _watch;
  final RestoreCartUseCase _restore;
  final SyncCartOwnerUseCase _syncOwner;
  final FetchCartUseCase _fetch;
  final FlushCartUseCase _flush;
  final AdjustCartLineUseCase _adjustLine;
  final SetCartLineQuantityUseCase _setLineQuantity;
  final RemoveCartLineUseCase _removeLine;
  final AddCartItemsUseCase _addItems;
  final ClearCartUseCase _clear;
  final ApplyCartCouponUseCase _applyCoupon;
  final RemoveCartCouponUseCase _removeCoupon;
  final ApplyCartLoyaltyUseCase _applyLoyalty;
  final RemoveCartLoyaltyUseCase _removeLoyalty;
  final SetCartExpressUseCase _setExpress;
  final ResetCartUseCase _reset;

  static const String _logName = 'CartCubit';
  StreamSubscription<CartSnapshot>? _subscription;

  /// Subscribes to the repository and paints the device copy. Idempotent.
  void start() {
    if (_subscription != null) return;
    _subscription = _watch(const NoParams()).listen(_onSnapshot);
    unawaited(_restore(const NoParams()).then(_logFailure));
  }

  void _onSnapshot(CartSnapshot snapshot) {
    safeEmit(
      state.copyWith(
        cart: snapshot.cart,
        isRestored: snapshot.isRestored,
        isSyncing: snapshot.isSyncing,
        hasPendingChanges: snapshot.hasPendingChanges,
        isUnsynced: snapshot.isUnsynced,
        failure: snapshot.failure,
        failedAction: snapshot.failedAction,
        quantityByProduct: snapshot.cart.quantityByProduct,
        revision: snapshot.revision,
      ),
    );
  }

  // ── Session hooks (app root) ─────────────────────────────────────────────

  /// The customer signed in (or the stored session was restored): fetch the
  /// merged cart and send what the guest had tapped meanwhile.
  Future<void> onSignedIn(String customerId) async => _logFailure(
    await _syncOwner(SyncCartOwnerParams(customerId: customerId)),
  );

  /// No stored session at launch.
  Future<void> onGuestSession() async =>
      _logFailure(await _syncOwner(const SyncCartOwnerParams()));

  /// Signed out (or a launch found the session gone): the mirror rebinds
  /// to the guest, which drops a customer's cart from the device.
  Future<void> onSignedOut() => onGuestSession();

  /// Line names come resolved for `Accept-Language`.
  Future<void> onLocaleChanged() async =>
      _logFailure(await _fetch(const NoParams()));

  /// The order took the cart with it.
  Future<void> onOrderPlaced() async {
    _logFailure(await _reset(const NoParams()));
    _logFailure(await _fetch(const NoParams()));
  }

  // ── Taps (optimistic) ────────────────────────────────────────────────────

  /// Product tile "+", the product page "add" ([quantity] pieces of the
  /// chosen [variantId]).
  void addCatalogProduct(
    CatalogProductEntity product, {
    String? variantId,
    int quantity = 1,
  }) => _tap(
    _adjustLine(
      AdjustCartLineParams(
        product: product,
        variantId: variantId,
        delta: quantity,
      ),
    ),
  );

  /// Product tile "−": one piece less of any line of the product.
  void removeProduct(String productId) {
    for (final line in state.cart.lines) {
      if (line.product.id != productId) continue;
      decrement(line);
      return;
    }
  }

  void increment(CartLineEntity line) => _tap(
    _adjustLine(
      AdjustCartLineParams(
        product: line.product,
        variantId: line.variantId,
        delta: 1,
      ),
    ),
  );

  void decrement(CartLineEntity line) => _tap(
    _adjustLine(
      AdjustCartLineParams(
        product: line.product,
        variantId: line.variantId,
        delta: -1,
      ),
    ),
  );

  void setLineQuantity(CartLineEntity line, int quantity) => _tap(
    _setLineQuantity(
      SetCartLineQuantityParams(ref: line.ref, quantity: quantity),
    ),
  );

  void removeLine(CartLineEntity line) =>
      _tap(_removeLine(RemoveCartLineParams(line.ref)));

  void _tap(Either<Failure, Unit> result) => result.fold(
    (failure) => safeEmit(
      state.copyWith(failure: failure, failedAction: CartAction.sync),
    ),
    (_) {},
  );

  // ── Server-confirmed actions (one at a time) ─────────────────────────────

  /// Re-reads the server cart. Unlike the write actions this one also runs
  /// while another is in flight (the repository serializes the lane anyway),
  /// because checkout asks for it right after a selection re-priced the cart
  /// — dropping it would leave the old delivery fee on screen.
  Future<bool> refresh() async {
    if (state.isBusy) {
      final result = await _fetch(const NoParams());
      result.fold(
        (failure) => safeEmit(
          state.copyWith(failure: failure, failedAction: CartAction.fetch),
        ),
        (_) {},
      );
      return result.isRight();
    }
    return _busy(CartAction.fetch, () => _fetch(const NoParams()));
  }

  /// Sends pending taps before checkout; `true` when the server has them all.
  Future<bool> prepareCheckout() =>
      _busy(CartAction.sync, () => _flush(const NoParams()));

  /// "Reorder": every line of a past order in one request.
  Future<bool> addItems(List<CartItemRequest> items) =>
      _busy(CartAction.addItems, () => _addItems(AddCartItemsParams(items)));

  Future<bool> clear() =>
      _busy(CartAction.clear, () => _clear(const NoParams()));

  Future<bool> applyCoupon(String code) =>
      _busy(CartAction.coupon, () => _applyCoupon(ApplyCartCouponParams(code)));

  Future<bool> removeCoupon() =>
      _busy(CartAction.coupon, () => _removeCoupon(const NoParams()));

  Future<bool> applyLoyalty(int points) => _busy(
    CartAction.loyalty,
    () => _applyLoyalty(ApplyCartLoyaltyParams(points)),
  );

  Future<bool> removeLoyalty() =>
      _busy(CartAction.loyalty, () => _removeLoyalty(const NoParams()));

  Future<bool> setExpress({required bool enabled}) => _busy(
    CartAction.express,
    () => _setExpress(SetCartExpressParams(enabled: enabled)),
  );

  Future<bool> _busy(
    CartAction action,
    Future<Either<Failure, Unit>> Function() operation,
  ) async {
    if (state.isBusy) return false;
    safeEmit(state.copyWith(busyAction: action));
    final result = await operation();
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          busyAction: CartAction.none,
          failure: failure,
          failedAction: action,
        ),
      ),
      (_) => safeEmit(state.copyWith(busyAction: CartAction.none)),
    );
    return result.isRight();
  }

  void _logFailure(Either<Failure, Unit> result) => result.fold(
    (failure) => log('session sync: ${failure.message}', name: _logName),
    (_) {},
  );

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;
    return super.close();
  }
}
