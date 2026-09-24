import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/cart_entity.dart';
import '../../../../core/domain/entities/order_status.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/branch_entity.dart';
import '../../domain/entities/checkout_draft.dart';
import '../../domain/entities/delivery_selection_entity.dart';
import '../../domain/entities/delivery_slot_entity.dart';
import '../../domain/usecases/get_branches_usecase.dart';
import '../../domain/usecases/get_delivery_slots_usecase.dart';
import '../../domain/usecases/place_order_usecase.dart';
import '../../domain/usecases/select_delivery_address_usecase.dart';
import '../../domain/usecases/select_pickup_branch_usecase.dart';
import 'checkout_state.dart';

/// Page-scoped checkout: loads branches + slots, selects the destination on
/// the server (one selection at a time; a stale reply is dropped), keeps
/// the draft, places the order once (double-submit guard).
class CheckoutCubit extends Cubit<CheckoutState>
    with SafeCubitMixin<CheckoutState> {
  CheckoutCubit({
    required this._getBranches,
    required this._getDeliverySlots,
    required this._selectDeliveryAddress,
    required this._selectPickupBranch,
    required this._placeOrder,
  }) : super(const CheckoutState());

  final GetBranchesUseCase _getBranches;
  final GetDeliverySlotsUseCase _getDeliverySlots;
  final SelectDeliveryAddressUseCase _selectDeliveryAddress;
  final SelectPickupBranchUseCase _selectPickupBranch;
  final PlaceOrderUseCase _placeOrder;

  int _selectionGeneration = 0;

  /// Loads the choices; [defaultAddressId] (the address book's default) is
  /// selected right away so the page opens priced.
  ///
  /// [expressSelected] is the cart's express flag: express is a flag the
  /// SERVER holds on the cart, so a customer who switched it on in the cart
  /// arrives here already paying the surcharge. Opening on "ASAP" would show
  /// a choice the order does not have.
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
    final slotsCall = _getDeliverySlots(const NoParams());
    final Either<Failure, List<BranchEntity>> branches = await branchesCall;
    final Either<Failure, List<DeliverySlotDayEntity>> slots = await slotsCall;
    final failure =
        branches.fold<Failure?>((failure) => failure, (_) => null) ??
        slots.fold<Failure?>((failure) => failure, (_) => null);
    if (failure != null) {
      safeEmit(
        state.copyWith(
          status: CheckoutStatus.error,
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
        slotDays: slots.getOrElse(() => const <DeliverySlotDayEntity>[]),
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

  Future<void> _select({
    required CheckoutDraft draft,
    required Future<Either<Failure, DeliverySelectionEntity>> Function() call,
  }) async {
    final generation = ++_selectionGeneration;
    safeEmit(state.copyWith(draft: draft, isSelecting: true));
    final result = await call();
    if (generation != _selectionGeneration) return; // a newer choice won
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          isSelecting: false,
          failure: failure,
          failedAction: CheckoutAction.select,
        ),
      ),
      (selection) =>
          safeEmit(state.copyWith(isSelecting: false, selection: selection)),
    );
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

  /// `POST /v1/orders`; a second tap while placing is ignored.
  Future<void> placeOrder() async {
    if (!state.canPlace) return;
    safeEmit(state.copyWith(isPlacing: true));
    final result = await _placeOrder(PlaceOrderParams(state.draft));
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          isPlacing: false,
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
