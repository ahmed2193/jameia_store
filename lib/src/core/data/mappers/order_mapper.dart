import '../../domain/entities/geo_point_entity.dart';
import '../../domain/entities/cart_entity.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/entities/order_fulfillment_entities.dart';
import '../../domain/entities/order_line_entity.dart';
import '../../domain/entities/order_progress_entities.dart';
import '../../domain/entities/order_status.dart';
import '../models/order_model.dart';

/// `OrderModel` (wire) → `OrderEntity`.
extension OrderMapper on OrderModel {
  OrderEntity toEntity() => OrderEntity(
    id: id,
    orderNumber: orderNumber,
    status: orderStatusOf(status),
    statusTimeline: [
      for (final event in statusTimeline)
        OrderStatusEvent(at: event.at, status: orderStatusOf(event.status)),
    ],
    fulfillmentMode: FulfillmentMode.fromWire(fulfillmentMode),
    branch: branch?.toEntity(),
    zone: zone?.toEntity(),
    address: address?.toEntity(),
    lines: [for (final line in lines) line.toEntity()],
    offerLines: [for (final line in offerLines) line.toEntity()],
    appliedOffers: [for (final offer in appliedOffers) offer.toEntity()],
    coupon: coupon == null
        ? null
        : OrderCouponEntity(code: coupon!.code, discountFils: coupon!.discount),
    loyalty: OrderLoyaltyEntity(
      pointsRedeemed: loyalty.pointsRedeemed,
      discountFils: loyalty.discount,
      pointsEarned: loyalty.pointsEarned,
    ),
    offerDiscountFils: offerDiscount,
    proDiscountFils: proDiscount,
    subtotalFils: subtotal,
    discountFils: discount,
    deliveryFeeFils: deliveryFee,
    totalFils: total,
    express: express,
    etaMinutes: etaMinutes,
    deliverySlot: deliverySlot?.toEntity(),
    payment: OrderPaymentEntity(
      method: paymentMethodOf(payment.method),
      status: switch (payment.status) {
        'pending' => OrderPaymentStatus.pending,
        'paid' => OrderPaymentStatus.paid,
        _ => OrderPaymentStatus.other,
      },
      walletUsedFils: payment.walletUsed,
    ),
    picking: picking?.toEntity(),
    delivery: delivery?.toEntity(),
    cancellation: cancellation?.toEntity(),
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  static OrderStatus orderStatusOf(String wire) => switch (wire) {
    'placed' => OrderStatus.placed,
    'confirmed' => OrderStatus.confirmed,
    'picking' => OrderStatus.picking,
    'ready' => OrderStatus.ready,
    'out_for_delivery' => OrderStatus.outForDelivery,
    'delivered' => OrderStatus.delivered,
    'delivery_failed' => OrderStatus.deliveryFailed,
    'cancelled' => OrderStatus.cancelled,
    _ => OrderStatus.other,
  };

  static OrderPaymentMethod paymentMethodOf(String wire) => switch (wire) {
    'cod' => OrderPaymentMethod.cod,
    'wallet' => OrderPaymentMethod.wallet,
    _ => OrderPaymentMethod.other,
  };
}

extension OrderListMapper on List<OrderModel> {
  List<OrderEntity> toEntities() => [
    for (final model in this) model.toEntity(),
  ];
}

extension OrderPlaceMapper on OrderPlaceModel {
  OrderPlaceEntity toEntity() =>
      OrderPlaceEntity(id: id, nameEn: name.en, nameAr: name.ar);
}

extension OrderAddressMapper on OrderAddressModel {
  OrderAddressEntity toEntity() => OrderAddressEntity(
    id: id,
    label: label,
    city: city,
    block: block,
    street: street,
    building: building,
    floor: floor,
    apartment: apartment,
    phone: phone,
    notes: notes,
    location: lat == null || lng == null
        ? null
        : GeoPointEntity(lat: lat!, lng: lng!),
  );
}

extension OrderLineMapper on OrderLineModel {
  OrderLineEntity toEntity() => OrderLineEntity(
    key: key,
    productId: productId,
    nameEn: name.en,
    nameAr: name.ar,
    image: image,
    productType: productType,
    variantId: variantId,
    variantNameEn: variantName.en,
    variantNameAr: variantName.ar,
    sku: sku,
    quantity: quantity,
    unitPriceFils: unitPrice,
    lineTotalFils: lineTotal,
  );
}

extension OrderOfferLineMapper on OrderOfferLineModel {
  OrderOfferLineEntity toEntity() => OrderOfferLineEntity(
    productId: productId,
    offerId: offerId,
    nameEn: name.en,
    nameAr: name.ar,
    image: image,
    offerNameEn: offerName.en,
    offerNameAr: offerName.ar,
    quantity: quantity,
  );
}

extension OrderAppliedOfferMapper on OrderAppliedOfferModel {
  OrderAppliedOfferEntity toEntity() => OrderAppliedOfferEntity(
    id: id,
    nameEn: name.en,
    nameAr: name.ar,
    rewardType: rewardType,
    discountFils: discount,
  );
}

extension OrderDeliverySlotMapper on OrderDeliverySlotModel {
  OrderDeliverySlotEntity toEntity() => OrderDeliverySlotEntity(
    templateId: templateId,
    date: date,
    start: start,
    end: end,
    startAt: startAt,
    endAt: endAt,
  );
}

extension OrderPickingMapper on OrderPickingModel {
  OrderPickingEntity toEntity() => OrderPickingEntity(
    pickerName: pickerName,
    startedAt: startedAt,
    unavailableLineKeys: unavailableLineKeys,
    substitutions: [
      for (final row in substitutions)
        OrderSubstitutionEntity(
          lineKey: row.lineKey,
          productNameEn: row.productName.en,
          productNameAr: row.productName.ar,
          variantNameEn: row.variantName.en,
          variantNameAr: row.variantName.ar,
        ),
    ],
  );
}

extension OrderDeliveryMapper on OrderDeliveryModel {
  OrderDeliveryEntity toEntity() => OrderDeliveryEntity(
    driverName: driverName,
    pickedUpAt: pickedUpAt,
    deliveredAt: deliveredAt,
    attempts: [
      for (final row in attempts)
        OrderDeliveryAttemptEntity(
          at: row.at,
          outcome: row.outcome,
          note: row.note,
        ),
    ],
    lastFailureReason: switch (lastFailureReason) {
      null => DeliveryFailureReason.none,
      'customer_absent' => DeliveryFailureReason.customerAbsent,
      'refused' => DeliveryFailureReason.refused,
      'wrong_address' => DeliveryFailureReason.wrongAddress,
      'unreachable' => DeliveryFailureReason.unreachable,
      _ => DeliveryFailureReason.other,
    },
  );
}

extension OrderCancellationMapper on OrderCancellationModel {
  OrderCancellationEntity toEntity() => OrderCancellationEntity(
    reason: switch (reason) {
      'changed_mind' => OrderCancellationReason.changedMind,
      'ordered_by_mistake' => OrderCancellationReason.orderedByMistake,
      'too_slow' => OrderCancellationReason.tooSlow,
      'found_elsewhere' => OrderCancellationReason.foundElsewhere,
      'out_of_stock' => OrderCancellationReason.outOfStock,
      'customer_unreachable' => OrderCancellationReason.customerUnreachable,
      'payment_failed' => OrderCancellationReason.paymentFailed,
      _ => OrderCancellationReason.other,
    },
    cancelledBy: switch (cancelledBy) {
      'customer' => OrderCancelledBy.customer,
      'staff' => OrderCancelledBy.staff,
      _ => OrderCancelledBy.other,
    },
    cancelledAt: cancelledAt,
    note: note,
  );
}
