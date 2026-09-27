import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/order_entity.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/branch_entity.dart';
import '../../domain/entities/checkout_block_reason.dart';
import '../../domain/entities/checkout_cart_facts.dart';
import '../../domain/entities/checkout_draft.dart';
import '../../domain/entities/checkout_eta.dart';
import '../../domain/entities/checkout_store_rules.dart';
import '../../domain/entities/delivery_selection_entity.dart';
import '../../../../core/domain/entities/delivery_slot_entity.dart';

enum CheckoutStatus { initial, loading, ready, placed, error }

/// Which checkout call a transient [CheckoutState.failure] belongs to.
enum CheckoutAction { none, load, select, place }

/// Something the cubit changed on the customer's behalf that the page must
/// announce. Transient like [CheckoutState.failure].
enum CheckoutNotice {
  none,

  /// The booked window is not offered for the new address: back to ASAP.
  slotReset,
}

class CheckoutState extends Equatable {
  const CheckoutState({
    this.status = CheckoutStatus.initial,
    this.draft = const CheckoutDraft(),
    this.selection,
    this.branches = const <BranchEntity>[],
    this.slotDays = const <DeliverySlotDayEntity>[],
    this.rules = CheckoutStoreRules.unknown,
    this.isSelecting = false,
    this.isPlacing = false,
    this.requiresSignIn = false,
    this.placedOrder,
    this.failure,
    this.failedAction = CheckoutAction.none,
    this.notice = CheckoutNotice.none,
  });

  final CheckoutStatus status;
  final CheckoutDraft draft;

  /// What the server resolved for the current destination (fee, branch, ETA).
  final DeliverySelectionEntity? selection;
  final List<BranchEntity> branches;

  /// Bookable windows for the current delivery selection; loaded after each
  /// address selection (the route needs one first).
  final List<DeliverySlotDayEntity> slotDays;

  /// The store settings (`GET /v1/init`); [CheckoutStoreRules.unknown] when
  /// they could not be read.
  final CheckoutStoreRules rules;

  /// A `/v1/delivery/select-*` call is in flight.
  final bool isSelecting;

  /// `POST /v1/orders` is in flight (the button cannot fire twice).
  final bool isPlacing;

  /// A customer-only call answered 401: the page shows the sign-in prompt.
  /// Sticky for the life of the page (signing in rebuilds it).
  final bool requiresSignIn;
  final OrderEntity? placedOrder;

  /// Transient: set on the state that reports a failed call, cleared by
  /// the next [copyWith]. [CheckoutStatus.error] keeps the load failure
  /// for the error view through [loadFailure].
  final Failure? failure;
  final CheckoutAction failedAction;

  /// Transient: cleared by the next [copyWith].
  final CheckoutNotice notice;

  Failure? get loadFailure =>
      status == CheckoutStatus.error && failedAction == CheckoutAction.load
      ? failure
      : null;
  bool get hasSelection => selection != null;

  /// Nothing in flight keeps the button from firing. What the order itself
  /// still lacks (destination, window, payment, the cart's own blocks) is
  /// [reasonFor]'s job.
  bool get canPlace =>
      status == CheckoutStatus.ready &&
      !isSelecting &&
      !isPlacing &&
      !requiresSignIn;
  bool get hasScheduledSlots => slotDays.isNotEmpty;

  /// The first reason the order cannot go with the cart's [cart] facts, or
  /// `null` ([CheckoutBlockReason.resolve] on this state).
  CheckoutBlockReason? reasonFor(CheckoutCartFacts cart) =>
      CheckoutBlockReason.resolve(
        draft: draft,
        hasSelection: hasSelection,
        rules: rules,
        cart: cart,
      );

  /// Exactly the part of this state [reasonFor] reads, so a selector keyed
  /// on it wakes only when a reason can change (saving a note does not
  /// move it unless the note crosses the limit). Built next to [reasonFor]
  /// so the two cannot drift apart.
  Object get blockInputs => (
    draft.hasDestination,
    draft.needsSlot,
    draft.notesTooLong,
    draft.paymentMethod,
    hasSelection,
    rules,
  );

  /// The estimate the "Expected" row and the ETA card show, with the cart's
  /// [cart] facts. Equatable, so a notes keystroke (a new draft, the same
  /// estimate) rebuilds nothing.
  CheckoutEta etaWith(CheckoutEtaCartFacts cart) => CheckoutEta.of(
    draft: draft,
    selection: selection,
    expressSelected: cart.expressSelected,
    expressEtaMinutes: cart.expressEtaMinutes,
    cartEtaMinutes: cart.cartEtaMinutes,
    branchOpen: cart.branchOpen,
    capacityAvailable: cart.capacityAvailable,
  );

  BranchEntity? branchById(String? id) {
    if (id == null) return null;
    for (final branch in branches) {
      if (branch.id == id) return branch;
    }
    return null;
  }

  CheckoutState copyWith({
    CheckoutStatus? status,
    CheckoutDraft? draft,
    DeliverySelectionEntity? selection,
    bool clearSelection = false,
    List<BranchEntity>? branches,
    List<DeliverySlotDayEntity>? slotDays,
    CheckoutStoreRules? rules,
    bool? isSelecting,
    bool? isPlacing,
    bool? requiresSignIn,
    OrderEntity? placedOrder,
    Failure? failure,
    CheckoutAction? failedAction,
    CheckoutNotice? notice,
  }) => CheckoutState(
    status: status ?? this.status,
    draft: draft ?? this.draft,
    selection: clearSelection ? null : selection ?? this.selection,
    branches: branches ?? this.branches,
    slotDays: slotDays ?? this.slotDays,
    rules: rules ?? this.rules,
    isSelecting: isSelecting ?? this.isSelecting,
    isPlacing: isPlacing ?? this.isPlacing,
    requiresSignIn: requiresSignIn ?? this.requiresSignIn,
    placedOrder: placedOrder ?? this.placedOrder,
    failure: failure,
    failedAction: failedAction ?? CheckoutAction.none,
    notice: notice ?? CheckoutNotice.none,
  );

  @override
  List<Object?> get props => [
    status,
    draft,
    selection,
    branches,
    slotDays,
    rules,
    isSelecting,
    isPlacing,
    requiresSignIn,
    placedOrder,
    failure,
    failedAction,
    notice,
  ];
}
