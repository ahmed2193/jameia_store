import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/order_entity.dart';
import '../../../../core/domain/entities/order_status.dart';

/// The four stages the tracking page shows, folded from the six wire
/// statuses the way a delivery app reads them: received (placed, confirmed)
/// → packing (picking, ready) → on the way (out for delivery; for a pickup
/// order: ready for pickup) → delivered (picked up).
enum OrderStage { received, packing, onTheWay, delivered }

/// How the page colours the journey.
enum OrderJourneyTone {
  /// Moving along.
  active,

  /// The last delivery attempt failed.
  attention,

  /// Delivered / picked up.
  done,

  /// Cancelled (or a status this build does not know).
  stopped,
}

/// Where an order stands, in the customer's words: the [stage] on the
/// four-segment bar, whether that stage is already [stageComplete] (packed,
/// waiting for a driver), the [tone], and the i18n keys of the headline and
/// the line under it. A pure function of the order — the widgets translate
/// the keys and never decide the copy themselves.
class OrderJourney extends Equatable {
  const OrderJourney({
    required this.stage,
    required this.tone,
    required this.headlineKey,
    required this.detailKey,
    this.stageComplete = false,
    this.detailName = '',
    this.detailReasonKey = '',
    this.pickup = false,
  });

  factory OrderJourney.of(OrderEntity order) {
    final journey = _of(order);
    return order.isPickup ? journey._forPickup() : journey;
  }

  static OrderJourney _of(OrderEntity order) {
    final picker = order.picking?.pickerName ?? '';
    final driver = order.delivery?.driverName ?? '';
    return switch (order.status) {
      OrderStatus.placed => const OrderJourney(
        stage: OrderStage.received,
        tone: OrderJourneyTone.active,
        headlineKey: 'orders.journey_received',
        detailKey: 'orders.journey_received_detail',
      ),
      OrderStatus.confirmed => const OrderJourney(
        stage: OrderStage.received,
        tone: OrderJourneyTone.active,
        headlineKey: 'orders.journey_confirmed',
        detailKey: 'orders.journey_confirmed_detail',
      ),
      OrderStatus.picking => OrderJourney(
        stage: OrderStage.packing,
        tone: OrderJourneyTone.active,
        headlineKey: 'orders.journey_packing',
        detailKey: picker.isEmpty
            ? 'orders.journey_packing_detail'
            : 'orders.journey_packing_by',
        detailName: picker,
      ),
      OrderStatus.ready when order.isPickup => _readyForPickup(order),
      OrderStatus.ready => const OrderJourney(
        stage: OrderStage.packing,
        stageComplete: true,
        tone: OrderJourneyTone.active,
        headlineKey: 'orders.journey_packed',
        detailKey: 'orders.journey_packed_detail',
      ),
      OrderStatus.outForDelivery => OrderJourney(
        stage: OrderStage.onTheWay,
        tone: OrderJourneyTone.active,
        headlineKey: 'orders.journey_on_the_way',
        detailKey: driver.isEmpty
            ? 'orders.journey_on_the_way_detail'
            : 'orders.journey_on_the_way_by',
        detailName: driver,
      ),
      OrderStatus.delivered => OrderJourney(
        stage: OrderStage.delivered,
        stageComplete: true,
        tone: OrderJourneyTone.done,
        headlineKey: order.isPickup
            ? 'orders.journey_picked_up'
            : 'orders.journey_delivered',
        detailKey: 'orders.journey_delivered_detail',
      ),
      OrderStatus.deliveryFailed => OrderJourney(
        stage: OrderStage.onTheWay,
        tone: OrderJourneyTone.attention,
        headlineKey: 'orders.journey_failed',
        detailKey: 'orders.delivery_failed_reason',
        detailReasonKey:
            (order.delivery?.lastFailureReason ?? DeliveryFailureReason.other)
                .labelKey,
      ),
      OrderStatus.cancelled => OrderJourney(
        stage: null,
        tone: OrderJourneyTone.stopped,
        headlineKey: 'orders.journey_cancelled',
        detailKey: order.cancellation?.byCustomer == true
            ? 'orders.cancelled_by_you'
            : 'orders.cancelled_by_store',
      ),
      OrderStatus.other => const OrderJourney(
        stage: null,
        tone: OrderJourneyTone.stopped,
        headlineKey: 'orders.journey_unknown',
        detailKey: 'orders.journey_unknown_detail',
      ),
    };
  }

  static OrderJourney _readyForPickup(OrderEntity order) {
    final branchEn = order.branch?.nameEn ?? '';
    final branchAr = order.branch?.nameAr ?? '';
    return OrderJourney(
      stage: OrderStage.onTheWay,
      tone: OrderJourneyTone.active,
      headlineKey: 'orders.journey_ready_pickup',
      detailKey: branchEn.isEmpty && branchAr.isEmpty
          ? 'orders.journey_ready_pickup_detail'
          : 'orders.journey_ready_pickup_at',
    );
  }

  OrderJourney _forPickup() => OrderJourney(
    stage: stage,
    stageComplete: stageComplete,
    tone: tone,
    headlineKey: headlineKey,
    detailKey: detailKey,
    detailName: detailName,
    detailReasonKey: detailReasonKey,
    pickup: true,
  );

  /// Segments on the bar.
  static const int stageCount = 4;

  /// `null` off the journey (cancelled, unknown): no bar.
  final OrderStage? stage;

  /// The current stage is finished and the next has not started.
  final bool stageComplete;
  final OrderJourneyTone tone;
  final String headlineKey;
  final String detailKey;

  /// The `{name}` of [detailKey] (the picker or the driver); empty when the
  /// key takes none. A pickup order's branch is named by the widget, which
  /// knows the language.
  final String detailName;

  /// An i18n key whose text fills `{reason}` of [detailKey]; empty when the
  /// key takes none.
  final String detailReasonKey;

  /// A pickup order: its third stage is "ready for pickup", its last one
  /// "picked up".
  final bool pickup;

  bool get isOnJourney => stage != null;

  /// 0-based index of [stage] on the bar.
  int? get stageIndex => stage?.index;

  /// Segments drawn full: every stage before the current one, plus the
  /// current one once it is complete — or once it is where the order stopped
  /// (a failed delivery marks its stage in the attention colour).
  int get filledSegments {
    final index = stageIndex;
    if (index == null) return 0;
    return stageComplete || tone == OrderJourneyTone.attention
        ? index + 1
        : index;
  }

  /// A stage is in progress (the bar animates its segment).
  bool get inProgress =>
      stage != null && !stageComplete && tone == OrderJourneyTone.active;

  /// The rider can be followed on the live map: a delivery on its way, not
  /// a pickup order, nor one delivered, cancelled or whose delivery failed.
  bool get tracksRider => !pickup && tone == OrderJourneyTone.active;

  /// i18n key of the current stage's name (the bar's semantics).
  String get stageLabelKey => stageLabelKeyOf(stage);

  /// i18n key of [stage]'s name for this order (pickup names differ).
  String stageLabelKeyOf(OrderStage? stage) => switch (stage) {
    OrderStage.received => 'orders.stage_received',
    OrderStage.packing => 'orders.stage_packing',
    OrderStage.onTheWay when pickup => 'orders.stage_ready_pickup',
    OrderStage.onTheWay => 'orders.stage_on_the_way',
    OrderStage.delivered when pickup => 'orders.stage_picked_up',
    OrderStage.delivered => 'orders.stage_delivered',
    null => 'orders.journey_unknown',
  };

  @override
  List<Object?> get props => [
    stage,
    stageComplete,
    tone,
    headlineKey,
    detailKey,
    detailName,
    detailReasonKey,
    pickup,
  ];
}
