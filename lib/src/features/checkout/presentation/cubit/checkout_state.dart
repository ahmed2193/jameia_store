import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/order_entity.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/branch_entity.dart';
import '../../domain/entities/checkout_draft.dart';
import '../../domain/entities/delivery_selection_entity.dart';
import '../../domain/entities/delivery_slot_entity.dart';

enum CheckoutStatus { initial, loading, ready, placed, error }

/// Which checkout call a transient [CheckoutState.failure] belongs to.
enum CheckoutAction { none, load, select, place }

class CheckoutState extends Equatable {
  const CheckoutState({
    this.status = CheckoutStatus.initial,
    this.draft = const CheckoutDraft(),
    this.selection,
    this.branches = const <BranchEntity>[],
    this.slotDays = const <DeliverySlotDayEntity>[],
    this.isSelecting = false,
    this.isPlacing = false,
    this.placedOrder,
    this.failure,
    this.failedAction = CheckoutAction.none,
  });

  final CheckoutStatus status;
  final CheckoutDraft draft;

  /// What the server resolved for the current destination (fee, branch, ETA).
  final DeliverySelectionEntity? selection;
  final List<BranchEntity> branches;
  final List<DeliverySlotDayEntity> slotDays;

  /// A `/v1/delivery/select-*` call is in flight.
  final bool isSelecting;

  /// `POST /v1/orders` is in flight (the button cannot fire twice).
  final bool isPlacing;
  final OrderEntity? placedOrder;

  /// Transient: set on the state that reports a failed call, cleared by
  /// the next [copyWith]. [CheckoutStatus.error] keeps the load failure
  /// for the error view through [loadFailure].
  final Failure? failure;
  final CheckoutAction failedAction;

  Failure? get loadFailure =>
      status == CheckoutStatus.error && failedAction == CheckoutAction.load
      ? failure
      : null;
  bool get isSignedOut => failure is UnauthorizedFailure;
  bool get canPlace =>
      status == CheckoutStatus.ready &&
      draft.isComplete &&
      selection != null &&
      !isSelecting &&
      !isPlacing;
  bool get hasScheduledSlots => slotDays.isNotEmpty;

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
    bool? isSelecting,
    bool? isPlacing,
    OrderEntity? placedOrder,
    Failure? failure,
    CheckoutAction? failedAction,
  }) => CheckoutState(
    status: status ?? this.status,
    draft: draft ?? this.draft,
    selection: clearSelection ? null : selection ?? this.selection,
    branches: branches ?? this.branches,
    slotDays: slotDays ?? this.slotDays,
    isSelecting: isSelecting ?? this.isSelecting,
    isPlacing: isPlacing ?? this.isPlacing,
    placedOrder: placedOrder ?? this.placedOrder,
    failure: failure,
    failedAction: failedAction ?? CheckoutAction.none,
  );

  @override
  List<Object?> get props => [
    status,
    draft,
    selection,
    branches,
    slotDays,
    isSelecting,
    isPlacing,
    placedOrder,
    failure,
    failedAction,
  ];
}
