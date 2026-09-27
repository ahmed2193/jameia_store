import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/cart_entity.dart';
import '../../../../core/domain/entities/delivery_slot_entity.dart';
import '../../../../core/domain/entities/order_status.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/branch_entity.dart';
import '../../domain/entities/checkout_cart_facts.dart';
import '../../domain/entities/checkout_draft.dart';
import '../../domain/entities/checkout_store_rules.dart';
import '../../domain/entities/delivery_selection_entity.dart';
import '../../domain/usecases/get_branches_usecase.dart';
import '../../domain/usecases/get_delivery_slots_usecase.dart';
import '../../domain/usecases/get_store_rules_usecase.dart';
import '../../domain/usecases/place_order_usecase.dart';
import '../../domain/usecases/select_delivery_address_usecase.dart';
import '../../domain/usecases/select_pickup_branch_usecase.dart';
import 'checkout_state.dart';

/// Page-scoped checkout: loads the branches and the store rules, selects
/// the destination on the server (one selection at a time; a stale reply is
/// dropped, a refused one puts the previous destination back), loads the
/// delivery windows after each address selection, keeps the draft, and
/// places the order once (double-submit guard).
class CheckoutCubit extends Cubit<CheckoutState>
    with SafeCubitMixin<CheckoutState> {
  CheckoutCubit({
    required this._getBranches,
    required this._getDeliverySlots,
    required this._selectDeliveryAddress,
    required this._selectPickupBranch,
    required this._placeOrder,
    required this._getStoreRules,
  }) : super(const CheckoutState());

  final GetBranchesUseCase _getBranches;
  final GetDeliverySlotsUseCase _getDeliverySlots;
  final SelectDeliveryAddressUseCase _selectDeliveryAddress;
  final SelectPickupBranchUseCase _selectPickupBranch;
  final PlaceOrderUseCase _placeOrder;
  final GetStoreRulesUseCase _getStoreRules;

  int _selectionGeneration = 0;
  int _slotsGeneration = 0;

  /// Loads the choices; [defaultAddressId] (the address book's default) is
  /// selected right away so the page opens priced.
  ///
  /// [expressSelected] is the cart's express flag: express is a flag the
  /// SERVER holds on the cart, so a customer who switched it on in the cart
  /// arrives here already paying the surcharge. Opening on "ASAP" would show
  /// a choice the order does not have.
  ///
  /// The delivery windows are NOT read here: the slots route answers only
  /// once the cart has a destination, so they follow the address selection.
  /// The store rules are optional: a failed read keeps
  /// [CheckoutStoreRules.unknown].
  Future<void> start({
    String? defaultAddressId,
    bool expressSelected = false,
  }) async {
    if (state.status == CheckoutStatus.loading) return; // one load at a time
    safeEmit(
      state.copyWith(
        status: CheckoutStatus.loading,
        draft: expressSelected
            ? state.draft.copyWith(timing: DeliveryTiming.express)
            : state.draft,
      ),
    );
    // Both calls start before either is awaited, so they still run together.
    final branchesCall = _getBranches(const NoParams());
    final rulesCall = _getStoreRules(const NoParams());
    final Either<Failure, List<BranchEntity>> branches = await branchesCall;
    final Either<Failure, CheckoutStoreRules> rules = await rulesCall;
    final failure = branches.fold<Failure?>((failure) => failure, (_) => null);
    if (failure != null) {
      safeEmit(
        state.copyWith(
          status: CheckoutStatus.error,
          // One sign-in signal for every call: the page reads only this.
          requiresSignIn: failure is UnauthorizedFailure ? true : null,
          failure: failure,
          failedAction: CheckoutAction.load,
        ),
      );
      return;
    }
    safeEmit(
      state.copyWith(
        status: CheckoutStatus.ready,
        branches: branches.getOrElse(() => const <BranchEntity>[]),
        rules: rules.getOrElse(() => CheckoutStoreRules.unknown),
      ),
    );
    if (defaultAddressId != null && defaultAddressId.isNotEmpty) {
      await selectAddress(defaultAddressId);
    }
  }

  Future<void> retry({
    String? defaultAddressId,
    bool expressSelected = false,
  }) => start(
    defaultAddressId: defaultAddressId,
    expressSelected: expressSelected,
  );

  Future<void> selectAddress(String addressId) => _select(
    draft: state.draft.copyWith(
      mode: FulfillmentMode.delivery,
      addressId: addressId,
    ),
    call: () => _selectDeliveryAddress(SelectDeliveryAddressParams(addressId)),
  );

  Future<void> selectBranch(String branchId) => _select(
    draft: state.draft.copyWith(
      mode: FulfillmentMode.pickup,
      branchId: branchId,
    ),
    call: () => _selectPickupBranch(SelectPickupBranchParams(branchId)),
  );

  /// Switches the mode; the destination of the other mode is re-selected on
  /// the server when it is already known.
  Future<void> setMode(FulfillmentMode mode) async {
    if (mode == state.draft.mode) return;
    final draft = state.draft;
    if (mode == FulfillmentMode.pickup) {
      final branchId = draft.branchId;
      if (branchId != null) return selectBranch(branchId);
      safeEmit(
        state.copyWith(draft: draft.copyWith(mode: mode), clearSelection: true),
      );
      return;
    }
    final addressId = draft.addressId;
    if (addressId != null) return selectAddress(addressId);
    safeEmit(
      state.copyWith(draft: draft.copyWith(mode: mode), clearSelection: true),
    );
  }

  /// One selection at a time: a reply that lands after a newer choice is
  /// dropped. A refused choice puts the previous destination back (the
  /// server still delivers to the one it holds, so the page must not show
  /// the refused one); a 401 turns the page into the sign-in prompt. After
  /// a delivery selection the windows are read for the new address; with a
  /// window booked, the selection stays in flight ([CheckoutState.canPlace]
  /// is off) until that window is confirmed or dropped, so the order can
  /// never go with the old address's window.
  Future<void> _select({
    required CheckoutDraft draft,
    required Future<Either<Failure, DeliverySelectionEntity>> Function() call,
  }) async {
    final generation = ++_selectionGeneration;
    final previous = state.draft;
    safeEmit(state.copyWith(draft: draft, isSelecting: true));
    final result = await call();
    if (generation != _selectionGeneration) return; // a newer choice won
    final selection = result.fold<DeliverySelectionEntity?>((failure) {
      safeEmit(
        state.copyWith(
          draft: state.draft.withDestinationOf(previous),
          isSelecting: false,
          requiresSignIn: failure is UnauthorizedFailure ? true : null,
          failure: failure,
          failedAction: CheckoutAction.select,
        ),
      );
      return null;
    }, (selection) => selection);
    if (selection == null) return;
    final recheckWindow = !draft.isPickup && state.draft.slot != null;
    safeEmit(state.copyWith(isSelecting: recheckWindow, selection: selection));
    if (draft.isPickup) return;
    await _loadSlots();
    if (recheckWindow && generation == _selectionGeneration) {
      safeEmit(state.copyWith(isSelecting: false));
    }
  }

  /// `GET /v1/delivery/slots` for the current delivery selection. Not fatal:
  /// a failure only hides the "Schedule" choice (the old address's windows
  /// do not apply to the new one). A booked window the new address does not
  /// offer (or that filled up) — or that could not be confirmed because the
  /// read failed — goes back to ASAP and the page says so.
  Future<void> _loadSlots() async {
    final generation = ++_slotsGeneration;
    final result = await _getDeliverySlots(const NoParams());
    if (generation != _slotsGeneration) return; // a newer read won
    result.fold(
      (_) => safeEmit(
        state.draft.slot == null
            ? state.copyWith(slotDays: const <DeliverySlotDayEntity>[])
            : state.copyWith(
                slotDays: const <DeliverySlotDayEntity>[],
                draft: state.draft.copyWith(
                  timing: DeliveryTiming.asap,
                  clearSlot: true,
                ),
                notice: CheckoutNotice.slotReset,
              ),
      ),
      (days) {
        final booked = state.draft.slot;
        if (booked == null) {
          safeEmit(state.copyWith(slotDays: days));
          return;
        }
        final fresh = _find(days, booked);
        safeEmit(
          fresh == null
              ? state.copyWith(
                  slotDays: days,
                  draft: state.draft.copyWith(
                    timing: DeliveryTiming.asap,
                    clearSlot: true,
                  ),
                  notice: CheckoutNotice.slotReset,
                )
              // The fresh copy carries the current capacity, so the sheet
              // still marks it as the chosen one.
              : state.copyWith(
                  slotDays: days,
                  draft: state.draft.copyWith(slot: fresh),
                ),
        );
      },
    );
  }

  /// The bookable window of [days] that is [booked] (same day, same
  /// template), or `null`.
  static DeliverySlotEntity? _find(
    List<DeliverySlotDayEntity> days,
    DeliverySlotEntity booked,
  ) {
    for (final day in days) {
      for (final slot in day.slots) {
        if (slot.isSameWindow(booked) && slot.isSelectable) return slot;
      }
    }
    return null;
  }

  void setTiming(DeliveryTiming timing) => safeEmit(
    state.copyWith(
      draft: state.draft.copyWith(
        timing: timing,
        clearSlot: timing != DeliveryTiming.scheduled,
      ),
    ),
  );

  void setSlot(DeliverySlotEntity slot) => safeEmit(
    state.copyWith(
      draft: state.draft.copyWith(timing: DeliveryTiming.scheduled, slot: slot),
    ),
  );

  void setPaymentMethod(OrderPaymentMethod method) => safeEmit(
    state.copyWith(draft: state.draft.copyWith(paymentMethod: method)),
  );

  void setNotes(String notes) =>
      safeEmit(state.copyWith(draft: state.draft.copyWith(notes: notes)));

  /// `POST /v1/orders` with the cart's [cart] facts (required: an order is
  /// never checked without them). A second tap while placing is ignored,
  /// and so is a tap while the cart is still moving ([cart] not settled).
  /// Whether the order may go is [PlaceOrderUseCase]'s rule; a blocked one
  /// is dropped here without a call or a failure (the button already says
  /// why). A 401 turns the page into the sign-in prompt.
  Future<void> placeOrder(CheckoutCartFacts cart) async {
    if (!state.canPlace || !cart.settled) return;
    final params = PlaceOrderParams(
      draft: state.draft,
      hasSelection: state.hasSelection,
      rules: state.rules,
      cart: cart,
    );
    if (params.blockReason != null) return;
    safeEmit(state.copyWith(isPlacing: true));
    final result = await _placeOrder(params);
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          isPlacing: false,
          requiresSignIn: failure is UnauthorizedFailure ? true : null,
          failure: failure,
          failedAction: CheckoutAction.place,
        ),
      ),
      (order) => safeEmit(
        state.copyWith(
          status: CheckoutStatus.placed,
          isPlacing: false,
          placedOrder: order,
        ),
      ),
    );
  }
}
