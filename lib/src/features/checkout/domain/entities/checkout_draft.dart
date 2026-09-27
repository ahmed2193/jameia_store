import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/cart_entity.dart';
import '../../../../core/domain/entities/order_status.dart';
import '../../../../core/domain/entities/delivery_slot_entity.dart';

/// When the order should go out.
enum DeliveryTiming { asap, express, scheduled }

/// What the customer chose on the checkout page. Delivery goes to a saved
/// address, pickup to a branch; the address / branch itself is selected on
/// the server (`/v1/delivery/select-*`), so only ids live here.
class CheckoutDraft extends Equatable {
  const CheckoutDraft({
    this.mode = FulfillmentMode.delivery,
    this.addressId,
    this.branchId,
    this.timing = DeliveryTiming.asap,
    this.slot,
    this.paymentMethod = OrderPaymentMethod.cod,
    this.notes = '',
  });

  /// `POST /v1/orders` → `notes` limit.
  static const int maxNotesLength = 256;

  final FulfillmentMode mode;
  final String? addressId;
  final String? branchId;
  final DeliveryTiming timing;
  final DeliverySlotEntity? slot;
  final OrderPaymentMethod paymentMethod;
  final String notes;

  bool get isPickup => mode == FulfillmentMode.pickup;
  bool get hasDestination => isPickup ? branchId != null : addressId != null;
  bool get needsSlot => timing == DeliveryTiming.scheduled && slot == null;
  bool get notesTooLong => notes.length > maxNotesLength;

  CheckoutDraft copyWith({
    FulfillmentMode? mode,
    String? addressId,
    String? branchId,
    DeliveryTiming? timing,
    DeliverySlotEntity? slot,
    bool clearSlot = false,
    OrderPaymentMethod? paymentMethod,
    String? notes,
  }) => CheckoutDraft(
    mode: mode ?? this.mode,
    addressId: addressId ?? this.addressId,
    branchId: branchId ?? this.branchId,
    timing: timing ?? this.timing,
    slot: clearSlot ? null : slot ?? this.slot,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    notes: notes ?? this.notes,
  );

  /// This draft with the destination of [other] — its mode, address and
  /// branch, nulls included — and everything else (timing, slot, payment,
  /// notes) kept. Puts a destination back after the server refused a new
  /// one, so the page never shows an address the order would not go to.
  CheckoutDraft withDestinationOf(CheckoutDraft other) => CheckoutDraft(
    mode: other.mode,
    addressId: other.addressId,
    branchId: other.branchId,
    timing: timing,
    slot: slot,
    paymentMethod: paymentMethod,
    notes: notes,
  );

  @override
  List<Object?> get props => [
    mode,
    addressId,
    branchId,
    timing,
    slot,
    paymentMethod,
    notes,
  ];
}
