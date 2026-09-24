import 'package:equatable/equatable.dart';

import '../localization/localized_pick.dart';
import 'order_status.dart';

/// A line the picker replaced (`picking.substitutedLines[]`).
class OrderSubstitutionEntity extends Equatable {
  const OrderSubstitutionEntity({
    required this.lineKey,
    this.productNameEn = '',
    this.productNameAr = '',
    this.variantNameEn = '',
    this.variantNameAr = '',
  });

  final String lineKey;
  final String productNameEn;
  final String productNameAr;
  final String variantNameEn;
  final String variantNameAr;

  String productNameFor(String languageCode) =>
      pickLocalized(languageCode, en: productNameEn, ar: productNameAr);
  String variantNameFor(String languageCode) =>
      pickLocalized(languageCode, en: variantNameEn, ar: variantNameAr);

  @override
  List<Object?> get props => [
    lineKey,
    productNameEn,
    productNameAr,
    variantNameEn,
    variantNameAr,
  ];
}

/// `picking` — present once a picker started.
class OrderPickingEntity extends Equatable {
  const OrderPickingEntity({
    this.pickerName = '',
    this.startedAt,
    this.unavailableLineKeys = const <String>[],
    this.substitutions = const <OrderSubstitutionEntity>[],
  });

  final String pickerName;
  final DateTime? startedAt;
  final List<String> unavailableLineKeys;
  final List<OrderSubstitutionEntity> substitutions;

  bool get hasChanges =>
      unavailableLineKeys.isNotEmpty || substitutions.isNotEmpty;

  @override
  List<Object?> get props => [
    pickerName,
    startedAt,
    unavailableLineKeys,
    substitutions,
  ];
}

/// One delivery attempt (`delivery.attempts[]`).
class OrderDeliveryAttemptEntity extends Equatable {
  const OrderDeliveryAttemptEntity({
    required this.at,
    this.outcome = '',
    this.note = '',
  });

  final DateTime at;
  final String outcome;
  final String note;

  @override
  List<Object?> get props => [at, outcome, note];
}

/// `delivery` — present once a driver picked the order up.
class OrderDeliveryEntity extends Equatable {
  const OrderDeliveryEntity({
    this.driverName = '',
    this.pickedUpAt,
    this.deliveredAt,
    this.attempts = const <OrderDeliveryAttemptEntity>[],
    this.lastFailureReason = DeliveryFailureReason.none,
  });

  final String driverName;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final List<OrderDeliveryAttemptEntity> attempts;
  final DeliveryFailureReason lastFailureReason;

  bool get hasFailure => lastFailureReason != DeliveryFailureReason.none;

  @override
  List<Object?> get props => [
    driverName,
    pickedUpAt,
    deliveredAt,
    attempts,
    lastFailureReason,
  ];
}

/// `cancellation` — present on a cancelled order.
class OrderCancellationEntity extends Equatable {
  const OrderCancellationEntity({
    this.reason = OrderCancellationReason.other,
    this.cancelledBy = OrderCancelledBy.other,
    this.cancelledAt,
    this.note = '',
  });

  final OrderCancellationReason reason;
  final OrderCancelledBy cancelledBy;
  final DateTime? cancelledAt;
  final String note;

  bool get byCustomer => cancelledBy == OrderCancelledBy.customer;

  @override
  List<Object?> get props => [reason, cancelledBy, cancelledAt, note];
}
