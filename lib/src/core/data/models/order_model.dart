import '../../error/exceptions.dart';
import 'json_read.dart';
import 'order_fulfillment_models.dart';
import 'order_line_models.dart';
import 'order_progress_models.dart';

export 'order_fulfillment_models.dart';
export 'order_line_models.dart';
export 'order_progress_models.dart';

/// An order as `GET /v1/orders/{id}`, the rows of `GET /v1/orders` and the
/// reply of `POST /v1/orders` send it. Shared by checkout and orders.
///
/// Reference: https://api.jm3eia.store/docs (Orders).
class OrderModel {
  const OrderModel({
    required this.id,
    required this.orderNumber,
    this.status = '',
    this.statusTimeline = const <OrderStatusEventModel>[],
    this.fulfillmentMode = '',
    this.branch,
    this.zone,
    this.address,
    this.lines = const <OrderLineModel>[],
    this.offerLines = const <OrderOfferLineModel>[],
    this.appliedOffers = const <OrderAppliedOfferModel>[],
    this.coupon,
    this.loyalty = const OrderLoyaltyModel(),
    this.offerDiscount = 0,
    this.proDiscount = 0,
    this.subtotal = 0,
    this.discount = 0,
    this.deliveryFee = 0,
    this.total = 0,
    this.express = false,
    this.etaMinutes,
    this.deliverySlot,
    this.payment = const OrderPaymentModel(),
    this.picking,
    this.delivery,
    this.cancellation,
    this.createdAt,
    this.updatedAt,
  });

  static const String mongoIdKey = '_id';
  static const String idKey = 'id';
  static const String orderNumberKey = 'orderNumber';
  static const String statusKey = 'status';
  static const String statusTimelineKey = 'statusTimeline';
  static const String fulfillmentModeKey = 'fulfillmentMode';
  static const String branchKey = 'branch';
  static const String zoneKey = 'zone';
  static const String addressKey = 'address';
  static const String linesKey = 'lines';
  static const String offerLinesKey = 'offerLines';
  static const String appliedOffersKey = 'appliedOffers';
  static const String couponKey = 'coupon';
  static const String loyaltyKey = 'loyalty';
  static const String offerDiscountKey = 'offerDiscount';
  static const String proDiscountKey = 'proDiscount';
  static const String subtotalKey = 'subtotal';
  static const String discountKey = 'discount';
  static const String deliveryFeeKey = 'deliveryFee';
  static const String totalKey = 'total';
  static const String expressKey = 'express';
  static const String etaMinutesKey = 'etaMinutes';
  static const String deliverySlotKey = 'deliverySlot';
  static const String paymentKey = 'payment';
  static const String pickingKey = 'picking';
  static const String deliveryKey = 'delivery';
  static const String cancellationKey = 'cancellation';
  static const String createdAtKey = 'createdAt';
  static const String updatedAtKey = 'updatedAt';
  static const String _logName = 'OrderModel';

  /// Throws [ParsingException] without an id or an order number.
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final id =
        JsonRead.string(json[mongoIdKey]) ?? JsonRead.string(json[idKey]);
    final orderNumber = JsonRead.string(json[orderNumberKey]);
    if (id == null || orderNumber == null) {
      throw const ParsingException('order: identity missing');
    }
    final branch = JsonRead.object(json[branchKey]);
    final zone = JsonRead.object(json[zoneKey]);
    final address = JsonRead.object(json[addressKey]);
    final coupon = JsonRead.object(json[couponKey]);
    final loyalty = JsonRead.object(json[loyaltyKey]);
    final slot = JsonRead.object(json[deliverySlotKey]);
    final payment = JsonRead.object(json[paymentKey]);
    final picking = JsonRead.object(json[pickingKey]);
    final delivery = JsonRead.object(json[deliveryKey]);
    final cancellation = JsonRead.object(json[cancellationKey]);
    final timeline = json[statusTimelineKey];
    return OrderModel(
      id: id,
      orderNumber: orderNumber,
      status: JsonRead.string(json[statusKey]) ?? '',
      statusTimeline: timeline is List
          ? <OrderStatusEventModel>[
              for (final row in timeline)
                if (row is Map)
                  ?OrderStatusEventModel.tryParse(row.cast<String, dynamic>()),
            ]
          : const <OrderStatusEventModel>[],
      fulfillmentMode: JsonRead.string(json[fulfillmentModeKey]) ?? '',
      branch: branch == null ? null : OrderPlaceModel.tryParse(branch),
      zone: zone == null ? null : OrderPlaceModel.tryParse(zone),
      address: address == null ? null : OrderAddressModel.fromJson(address),
      lines: JsonRead.rows(
        json[linesKey],
        OrderLineModel.fromJson,
        logName: _logName,
      ),
      offerLines: JsonRead.rows(
        json[offerLinesKey],
        OrderOfferLineModel.fromJson,
        logName: _logName,
      ),
      appliedOffers: JsonRead.rows(
        json[appliedOffersKey],
        OrderAppliedOfferModel.fromJson,
        logName: _logName,
      ),
      coupon: coupon == null ? null : OrderCouponModel.tryParse(coupon),
      loyalty: loyalty == null
          ? const OrderLoyaltyModel()
          : OrderLoyaltyModel.fromJson(loyalty),
      offerDiscount: JsonRead.integer(json[offerDiscountKey]) ?? 0,
      proDiscount: JsonRead.integer(json[proDiscountKey]) ?? 0,
      subtotal: JsonRead.integer(json[subtotalKey]) ?? 0,
      discount: JsonRead.integer(json[discountKey]) ?? 0,
      deliveryFee: JsonRead.integer(json[deliveryFeeKey]) ?? 0,
      total: JsonRead.integer(json[totalKey]) ?? 0,
      express: JsonRead.flag(json[expressKey]),
      etaMinutes: JsonRead.integer(json[etaMinutesKey]),
      deliverySlot: slot == null ? null : OrderDeliverySlotModel.tryParse(slot),
      payment: payment == null
          ? const OrderPaymentModel()
          : OrderPaymentModel.fromJson(payment),
      picking: picking == null ? null : OrderPickingModel.fromJson(picking),
      delivery: delivery == null ? null : OrderDeliveryModel.fromJson(delivery),
      cancellation: cancellation == null
          ? null
          : OrderCancellationModel.fromJson(cancellation),
      createdAt: JsonRead.dateTime(json[createdAtKey]),
      updatedAt: JsonRead.dateTime(json[updatedAtKey]),
    );
  }

  final String id;
  final String orderNumber;
  final String status;
  final List<OrderStatusEventModel> statusTimeline;
  final String fulfillmentMode;
  final OrderPlaceModel? branch;
  final OrderPlaceModel? zone;
  final OrderAddressModel? address;
  final List<OrderLineModel> lines;
  final List<OrderOfferLineModel> offerLines;
  final List<OrderAppliedOfferModel> appliedOffers;
  final OrderCouponModel? coupon;
  final OrderLoyaltyModel loyalty;
  final int offerDiscount;
  final int proDiscount;
  final int subtotal;
  final int discount;
  final int deliveryFee;
  final int total;
  final bool express;
  final int? etaMinutes;
  final OrderDeliverySlotModel? deliverySlot;
  final OrderPaymentModel payment;
  final OrderPickingModel? picking;
  final OrderDeliveryModel? delivery;
  final OrderCancellationModel? cancellation;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
