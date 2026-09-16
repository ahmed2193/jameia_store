import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// TODO(P2.9-boundary): CartItem is the cart feature's core line type, supplied
// by CartCubit and passed straight into placeOrder — kept as the core DTO at
// this cross-feature boundary rather than a checkout entity.
import '../../../../core/data/models/models.dart' show CartItem;
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/checkout_draft.dart';
import '../../domain/entities/keeta_address_entity.dart';
import '../../domain/entities/keeta_order_entity.dart';
import '../../domain/entities/shop_entity.dart';
import '../../domain/repositories/checkout_repository.dart';

enum CheckoutStatus { initial, loading, ready, placing, placed, error }

/// State for the `order_confirm_global` checkout screen. Holds the loaded
/// context (shop / delivery address / available-coupon count), the user's
/// in-progress [CheckoutDraft] selections, and — once committed — the placed
/// order for deep-linking to tracking.
///
/// Purely-ephemeral UI (dialogs, the on-time promise sheet) stays in the screen;
/// this cubit owns only the business state.
class CheckoutState extends Equatable {
  const CheckoutState({
    this.status = CheckoutStatus.initial,
    this.shop,
    this.address,
    this.availableCouponCount = 0,
    this.draft = const CheckoutDraft(),
    this.placedOrder,
    this.error,
  });

  final CheckoutStatus status;
  final ShopEntity? shop;
  final KeetaAddressEntity? address;
  final int availableCouponCount;
  final CheckoutDraft draft;

  /// The committed order, set once [CheckoutStatus.placed] is reached.
  final KeetaOrderEntity? placedOrder;
  final String? error;

  CheckoutState copyWith({
    CheckoutStatus? status,
    ShopEntity? shop,
    KeetaAddressEntity? address,
    int? availableCouponCount,
    CheckoutDraft? draft,
    KeetaOrderEntity? placedOrder,
    String? error,
  }) =>
      CheckoutState(
        status: status ?? this.status,
        shop: shop ?? this.shop,
        address: address ?? this.address,
        availableCouponCount: availableCouponCount ?? this.availableCouponCount,
        draft: draft ?? this.draft,
        placedOrder: placedOrder ?? this.placedOrder,
        error: error ?? this.error,
      );

  @override
  List<Object?> get props => [
        status,
        shop,
        address,
        availableCouponCount,
        draft,
        placedOrder,
        error,
      ];
}

/// Page-scoped cubit — resolved via `sl<CheckoutCubit>()` and started with the
/// shop id (`..start(shopId)`) from the screen. Talks to the [CheckoutRepository]
/// directly (the pass-through use cases were collapsed). Owns the checkout draft
/// + place-order commit; the shared cart snapshot is passed into [placeOrder] so
/// the two cubits stay decoupled.
class CheckoutCubit extends Cubit<CheckoutState>
    with SafeCubitMixin<CheckoutState> {
  CheckoutCubit({required CheckoutRepository repository})
      : _repository = repository,
        super(const CheckoutState());

  final CheckoutRepository _repository;

  /// The last shop id passed to [start] — kept so [retry] can re-run the
  /// context load after a failure without the screen re-supplying it.
  String? _shopId;

  /// Load the first-frame context for [shopId] (shop / address / coupon count).
  Future<void> start(String shopId) async {
    _shopId = shopId;
    safeEmit(state.copyWith(status: CheckoutStatus.loading));
    final result = await _repository.getContext(shopId);
    result.fold(
      (failure) => safeEmit(state.copyWith(
        status: CheckoutStatus.error,
        error: failure.message,
      )),
      (ctx) => safeEmit(state.copyWith(
        status: CheckoutStatus.ready,
        shop: ctx.shop,
        address: ctx.address,
        availableCouponCount: ctx.availableCouponCount,
      )),
    );
  }

  /// Re-run [start] with the last shop id after a load failure — backs the
  /// error-state retry button so the screen needn't re-supply the id.
  Future<void> retry() async {
    final id = _shopId;
    if (id != null) await start(id);
  }

  // ── Draft selections ────────────────────────────────────────────────────────

  void setDropOff(DropOffOption dropOff) =>
      safeEmit(state.copyWith(draft: state.draft.copyWith(dropOff: dropOff)));

  void setCutlery(bool cutlery) =>
      safeEmit(state.copyWith(draft: state.draft.copyWith(cutlery: cutlery)));

  void setTip(double tip) =>
      safeEmit(state.copyWith(draft: state.draft.copyWith(tip: tip)));

  void setPayment(PaymentMethod method) =>
      safeEmit(state.copyWith(draft: state.draft.copyWith(payMethod: method)));

  /// Apply the coupon picked on the coupons screen (identified by [couponId]); a
  /// validation failure leaves the current selection untouched (matches the
  /// original picker behaviour).
  Future<void> applyCoupon(String couponId) async {
    final result = await _repository.applyCoupon(couponId);
    result.fold(
      (_) {},
      (applied) =>
          safeEmit(state.copyWith(draft: state.draft.copyWith(coupon: applied))),
    );
  }

  // ── Commit ────────────────────────────────────────────────────────────────

  /// Place the order from the current draft + the passed cart snapshot. The
  /// screen bridges the shared cart (clears it) once [CheckoutStatus.placed].
  Future<void> placeOrder({
    required ShopEntity shop,
    required List<CartItem> lines,
    required double subtotal,
  }) async {
    safeEmit(state.copyWith(status: CheckoutStatus.placing));
    final result = await _repository.placeOrder(
      shop: shop,
      lines: lines,
      subtotal: subtotal,
      draft: state.draft,
    );
    result.fold(
      (failure) => safeEmit(state.copyWith(
        status: CheckoutStatus.error,
        error: failure.message,
      )),
      (order) => safeEmit(state.copyWith(
        status: CheckoutStatus.placed,
        placedOrder: order,
      )),
    );
  }
}
