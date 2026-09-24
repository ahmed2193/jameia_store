import 'package:equatable/equatable.dart';

import 'cart_entity.dart';
import 'cart_item_request.dart';
import 'catalog_product_entity.dart';
import 'order_fulfillment_entities.dart';
import 'order_line_entity.dart';
import 'order_progress_entities.dart';
import 'order_status.dart';

/// One step of `statusTimeline[]`.
class OrderStatusEvent extends Equatable {
  const OrderStatusEvent({required this.at, required this.status});

  final DateTime at;
  final OrderStatus status;

  @override
  List<Object?> get props => [at, status];
}

/// A customer order as `GET /v1/orders/{id}` returns it. Shared by checkout
/// (the reply of `POST /v1/orders`) and orders (list, tracking, invoice,
/// review, reorder), so it lives in `core/domain`. Money in fils.
class OrderEntity extends Equatable {
  const OrderEntity({
    required this.id,
    required this.orderNumber,
    this.status = OrderStatus.other,
    this.statusTimeline = const <OrderStatusEvent>[],
    this.fulfillmentMode = FulfillmentMode.delivery,
    this.branch,
    this.zone,
    this.address,
    this.lines = const <OrderLineEntity>[],
    this.offerLines = const <OrderOfferLineEntity>[],
    this.appliedOffers = const <OrderAppliedOfferEntity>[],
    this.coupon,
    this.loyalty = const OrderLoyaltyEntity(),
    this.offerDiscountFils = 0,
    this.proDiscountFils = 0,
    this.subtotalFils = 0,
    this.discountFils = 0,
    this.deliveryFeeFils = 0,
    this.totalFils = 0,
    this.express = false,
    this.etaMinutes,
    this.deliverySlot,
    this.payment = const OrderPaymentEntity(),
    this.picking,
    this.delivery,
    this.cancellation,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String orderNumber;
  final OrderStatus status;
  final List<OrderStatusEvent> statusTimeline;
  final FulfillmentMode fulfillmentMode;

  bool get isPickup => fulfillmentMode == FulfillmentMode.pickup;
  final OrderPlaceEntity? branch;
  final OrderPlaceEntity? zone;
  final OrderAddressEntity? address;
  final List<OrderLineEntity> lines;
  final List<OrderOfferLineEntity> offerLines;
  final List<OrderAppliedOfferEntity> appliedOffers;
  final OrderCouponEntity? coupon;
  final OrderLoyaltyEntity loyalty;
  final int offerDiscountFils;
  final int proDiscountFils;
  final int subtotalFils;
  final int discountFils;
  final int deliveryFeeFils;
  final int totalFils;
  final bool express;
  final int? etaMinutes;
  final OrderDeliverySlotEntity? deliverySlot;
  final OrderPaymentEntity payment;
  final OrderPickingEntity? picking;
  final OrderDeliveryEntity? delivery;
  final OrderCancellationEntity? cancellation;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isTerminal => status.isTerminal;
  bool get canCancel => status.isCancellable;
  bool get canReview => status == OrderStatus.delivered;
  OrderStatusGroup get group => status.group;

  int get itemCount {
    var total = 0;
    for (final line in lines) {
      total += line.quantity;
    }
    return total;
  }

  /// The paid lines as a cart request ("reorder").
  List<CartItemRequest> get reorderItems => [
    for (final line in lines)
      CartItemRequest(
        productId: line.productId,
        variantId: line.variantId,
        quantity: line.quantity,
      ),
  ];

  /// The step of the tracking progress bar, or `null` (cancelled / failed).
  int? get progressStep => status.progressStep;

  double get subtotalKd => subtotalFils / CatalogProductEntity.filsPerDinar;
  double get discountKd => discountFils / CatalogProductEntity.filsPerDinar;
  double get offerDiscountKd =>
      offerDiscountFils / CatalogProductEntity.filsPerDinar;
  double get proDiscountKd =>
      proDiscountFils / CatalogProductEntity.filsPerDinar;
  double get deliveryFeeKd =>
      deliveryFeeFils / CatalogProductEntity.filsPerDinar;
  double get totalKd => totalFils / CatalogProductEntity.filsPerDinar;

  @override
  List<Object?> get props => [
    id,
    orderNumber,
    status,
    statusTimeline,
    fulfillmentMode,
    branch,
    zone,
    address,
    lines,
    offerLines,
    appliedOffers,
    coupon,
    loyalty,
    offerDiscountFils,
    proDiscountFils,
    subtotalFils,
    discountFils,
    deliveryFeeFils,
    totalFils,
    express,
    etaMinutes,
    deliverySlot,
    payment,
    picking,
    delivery,
    cancellation,
    createdAt,
    updatedAt,
  ];
}
