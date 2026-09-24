import 'package:equatable/equatable.dart';

import '../localization/localized_pick.dart';
import 'catalog_product_entity.dart';
import 'geo_point_entity.dart';
import 'order_status.dart';

/// The branch that serves the order (`branch`) or its zone (`zone`).
class OrderPlaceEntity extends Equatable {
  const OrderPlaceEntity({
    required this.id,
    this.nameEn = '',
    this.nameAr = '',
  });

  final String id;
  final String nameEn;
  final String nameAr;

  String nameFor(String languageCode) =>
      pickLocalized(languageCode, en: nameEn, ar: nameAr);

  @override
  List<Object?> get props => [id, nameEn, nameAr];
}

/// Where a delivery order goes (`address`), as the order froze it.
class OrderAddressEntity extends Equatable {
  const OrderAddressEntity({
    this.id,
    this.label = '',
    this.city = '',
    this.block = '',
    this.street = '',
    this.building = '',
    this.floor = '',
    this.apartment = '',
    this.phone = '',
    this.notes = '',
    this.location,
  });

  final String? id;
  final String label;
  final String city;
  final String block;
  final String street;
  final String building;
  final String floor;
  final String apartment;
  final String phone;
  final String notes;
  final GeoPointEntity? location;

  /// "City, Block 3, Street 12, Building 7" — the parts that are set.
  String get summary => [
    city,
    block,
    street,
    building,
    floor,
    apartment,
  ].where((part) => part.isNotEmpty).join(', ');

  @override
  List<Object?> get props => [
    id,
    label,
    city,
    block,
    street,
    building,
    floor,
    apartment,
    phone,
    notes,
    location,
  ];
}

/// The booked delivery window (`deliverySlot`).
class OrderDeliverySlotEntity extends Equatable {
  const OrderDeliverySlotEntity({
    required this.templateId,
    required this.date,
    this.start = '',
    this.end = '',
    this.startAt,
    this.endAt,
  });

  final String templateId;

  /// `YYYY-MM-DD`.
  final String date;

  /// `HH:mm`.
  final String start;
  final String end;
  final DateTime? startAt;
  final DateTime? endAt;

  /// The booked calendar day, parsed from [date] so the UI can write it in the
  /// customer's language instead of showing the wire `YYYY-MM-DD`. Parsed from
  /// [date] and not from [startAt], which is UTC and can fall on the day
  /// before or after once it is turned local.
  DateTime? get day => DateTime.tryParse(date);

  @override
  List<Object?> get props => [templateId, date, start, end, startAt, endAt];
}

/// `payment`.
class OrderPaymentEntity extends Equatable {
  const OrderPaymentEntity({
    this.method = OrderPaymentMethod.other,
    this.status = OrderPaymentStatus.pending,
    this.walletUsedFils = 0,
  });

  final OrderPaymentMethod method;
  final OrderPaymentStatus status;
  final int walletUsedFils;

  bool get isPaid => status == OrderPaymentStatus.paid;

  @override
  List<Object?> get props => [method, status, walletUsedFils];
}

/// `coupon`.
class OrderCouponEntity extends Equatable {
  const OrderCouponEntity({required this.code, this.discountFils = 0});

  final String code;
  final int discountFils;

  double get discountKd => discountFils / CatalogProductEntity.filsPerDinar;

  @override
  List<Object?> get props => [code, discountFils];
}

/// `loyalty`.
class OrderLoyaltyEntity extends Equatable {
  const OrderLoyaltyEntity({
    this.pointsRedeemed = 0,
    this.discountFils = 0,
    this.pointsEarned = 0,
  });

  final int pointsRedeemed;
  final int discountFils;
  final int pointsEarned;

  double get discountKd => discountFils / CatalogProductEntity.filsPerDinar;

  @override
  List<Object?> get props => [pointsRedeemed, discountFils, pointsEarned];
}
