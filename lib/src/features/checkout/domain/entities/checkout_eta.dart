import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/delivery_slot_entity.dart';
import 'checkout_draft.dart';
import 'delivery_selection_entity.dart';

/// What the "Expected" row can honestly say.
enum CheckoutEtaKind {
  /// No destination resolved yet.
  unknown,

  /// As soon as possible, with the server's estimate.
  asap,

  /// Express, with the express estimate.
  express,

  /// A delivery window the customer booked.
  scheduled,

  /// Pickup: when the branch has it ready.
  pickup,

  /// The serving branch is closed (nothing to estimate).
  branchClosed,

  /// The branch has no capacity (nothing to estimate).
  noCapacity,
}

/// What the estimate needs from the app-global cart, as values: express on
/// the order and its estimate, the cart's own estimate, and whether the
/// serving branch is open with capacity. A record, so equal carts compare
/// equal in a selector.
typedef CheckoutEtaCartFacts = ({
  bool expressSelected,
  int? expressEtaMinutes,
  int? cartEtaMinutes,
  bool branchOpen,
  bool capacityAvailable,
});

/// The delivery estimate of the checkout, from real fields only: the
/// selection's and the cart's `etaMinutes`, the cart's express estimate, or
/// the booked window. Never a promise: [arrivesAround] is rounded up.
class CheckoutEta extends Equatable {
  const CheckoutEta({
    this.kind = CheckoutEtaKind.unknown,
    this.minutes,
    this.slot,
    this.expressFaster = false,
  });

  static const CheckoutEta unknown = CheckoutEta();

  /// The clock time is rounded up to this many minutes.
  static const int roundToMinutes = 5;

  /// Rules, first match wins: no selection → unknown; a booked delivery
  /// window → scheduled (a window is its own promise); a closed branch or no
  /// capacity → that state (pickup too: nothing will be ready); pickup → the
  /// selection's minutes; express chosen and on the cart → express (express
  /// minutes, else the cart's), flagged [expressFaster] only when it really
  /// beats the standard estimate; otherwise ASAP (the cart's minutes, else
  /// the selection's).
  factory CheckoutEta.of({
    required CheckoutDraft draft,
    required DeliverySelectionEntity? selection,
    required bool expressSelected,
    required int? expressEtaMinutes,
    required int? cartEtaMinutes,
    required bool branchOpen,
    required bool capacityAvailable,
  }) {
    if (selection == null) return unknown;
    final slot = draft.slot;
    if (!draft.isPickup &&
        draft.timing == DeliveryTiming.scheduled &&
        slot != null) {
      return CheckoutEta(kind: CheckoutEtaKind.scheduled, slot: slot);
    }
    if (!branchOpen) {
      return const CheckoutEta(kind: CheckoutEtaKind.branchClosed);
    }
    if (!capacityAvailable) {
      return const CheckoutEta(kind: CheckoutEtaKind.noCapacity);
    }
    if (draft.isPickup) {
      return CheckoutEta(
        kind: CheckoutEtaKind.pickup,
        minutes: selection.etaMinutes,
      );
    }
    if (draft.timing == DeliveryTiming.express && expressSelected) {
      final minutes = expressEtaMinutes ?? cartEtaMinutes;
      final standard = selection.etaMinutes;
      return CheckoutEta(
        kind: CheckoutEtaKind.express,
        minutes: minutes,
        expressFaster:
            minutes != null && standard != null && minutes < standard,
      );
    }
    return CheckoutEta(
      kind: CheckoutEtaKind.asap,
      minutes: cartEtaMinutes ?? selection.etaMinutes,
    );
  }

  final CheckoutEtaKind kind;

  /// Estimated minutes (ASAP, express, pickup); `null` when the server gave
  /// none.
  final int? minutes;

  /// The booked window ([CheckoutEtaKind.scheduled]).
  final DeliverySlotEntity? slot;

  /// Express beats the standard estimate (both known) — the only case the
  /// row may show the bolt.
  final bool expressFaster;

  /// The ETA card has a real value to show: an ASAP / express estimate or a
  /// booked window.
  bool get showsCard => switch (kind) {
    CheckoutEtaKind.asap || CheckoutEtaKind.express => minutes != null,
    CheckoutEtaKind.scheduled => slot != null,
    _ => false,
  };

  /// The clock time the order should arrive around (ASAP / express only):
  /// [now] without its seconds, plus [minutes], rounded UP to the next
  /// [roundToMinutes] — so it never says earlier than the server did.
  DateTime? arrivesAround(DateTime now) {
    final estimate = minutes;
    if (estimate == null) return null;
    if (kind != CheckoutEtaKind.asap && kind != CheckoutEtaKind.express) {
      return null;
    }
    final at = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    ).add(Duration(minutes: estimate));
    final over = at.minute % roundToMinutes;
    return over == 0 ? at : at.add(Duration(minutes: roundToMinutes - over));
  }

  @override
  List<Object?> get props => [kind, minutes, slot, expressFaster];
}
