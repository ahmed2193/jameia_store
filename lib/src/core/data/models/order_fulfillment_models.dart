import 'json_read.dart';
import 'localized_text_model.dart';

/// `statusTimeline[]`.
class OrderStatusEventModel {
  const OrderStatusEventModel({required this.at, required this.status});

  static const String atKey = 'at';
  static const String statusKey = 'status';

  /// `null` when the row has no readable date.
  static OrderStatusEventModel? tryParse(Map<String, dynamic> json) {
    final at = JsonRead.dateTime(json[atKey]);
    if (at == null) return null;
    return OrderStatusEventModel(
      at: at,
      status: JsonRead.string(json[statusKey]) ?? '',
    );
  }

  final DateTime at;
  final String status;
}

/// `branch` / `zone`: `{ id, name: { en, ar } }`.
class OrderPlaceModel {
  const OrderPlaceModel({
    required this.id,
    this.name = LocalizedTextModel.empty,
  });

  static const String idKey = 'id';
  static const String nameKey = 'name';

  static OrderPlaceModel? tryParse(Map<String, dynamic> json) {
    final id = JsonRead.string(json[idKey]);
    if (id == null) return null;
    return OrderPlaceModel(
      id: id,
      name: LocalizedTextModel.parse(json[nameKey]),
    );
  }

  final String id;
  final LocalizedTextModel name;
}

/// `address` of a delivery order.
class OrderAddressModel {
  const OrderAddressModel({
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
    this.lat,
    this.lng,
  });

  static const String idKey = 'id';
  static const String labelKey = 'label';
  static const String cityKey = 'city';
  static const String blockKey = 'block';
  static const String streetKey = 'street';
  static const String buildingKey = 'building';
  static const String floorKey = 'floor';
  static const String apartmentKey = 'apartment';
  static const String phoneKey = 'phone';
  static const String notesKey = 'notes';
  static const String latKey = 'lat';
  static const String lngKey = 'lng';

  factory OrderAddressModel.fromJson(Map<String, dynamic> json) =>
      OrderAddressModel(
        id: JsonRead.string(json[idKey]),
        label: JsonRead.string(json[labelKey]) ?? '',
        city: JsonRead.string(json[cityKey]) ?? '',
        block: JsonRead.string(json[blockKey]) ?? '',
        street: JsonRead.string(json[streetKey]) ?? '',
        building: JsonRead.string(json[buildingKey]) ?? '',
        floor: JsonRead.string(json[floorKey]) ?? '',
        apartment: JsonRead.string(json[apartmentKey]) ?? '',
        phone: JsonRead.string(json[phoneKey]) ?? '',
        notes: JsonRead.string(json[notesKey]) ?? '',
        lat: JsonRead.decimal(json[latKey]),
        lng: JsonRead.decimal(json[lngKey]),
      );

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
  final double? lat;
  final double? lng;
}

/// `deliverySlot`.
class OrderDeliverySlotModel {
  const OrderDeliverySlotModel({
    required this.templateId,
    required this.date,
    this.start = '',
    this.end = '',
    this.startAt,
    this.endAt,
  });

  static const String templateIdKey = 'templateId';
  static const String dateKey = 'date';
  static const String startKey = 'start';
  static const String endKey = 'end';
  static const String startAtKey = 'startAt';
  static const String endAtKey = 'endAt';

  static OrderDeliverySlotModel? tryParse(Map<String, dynamic> json) {
    final templateId = JsonRead.string(json[templateIdKey]);
    final date = JsonRead.string(json[dateKey]);
    if (templateId == null || date == null) return null;
    return OrderDeliverySlotModel(
      templateId: templateId,
      date: date,
      start: JsonRead.string(json[startKey]) ?? '',
      end: JsonRead.string(json[endKey]) ?? '',
      startAt: JsonRead.dateTime(json[startAtKey]),
      endAt: JsonRead.dateTime(json[endAtKey]),
    );
  }

  final String templateId;
  final String date;
  final String start;
  final String end;
  final DateTime? startAt;
  final DateTime? endAt;
}

/// `payment`.
class OrderPaymentModel {
  const OrderPaymentModel({
    this.method = '',
    this.status = '',
    this.walletUsed = 0,
  });

  static const String methodKey = 'method';
  static const String statusKey = 'status';
  static const String walletUsedKey = 'walletUsed';

  factory OrderPaymentModel.fromJson(Map<String, dynamic> json) =>
      OrderPaymentModel(
        method: JsonRead.string(json[methodKey]) ?? '',
        status: JsonRead.string(json[statusKey]) ?? '',
        walletUsed: JsonRead.integer(json[walletUsedKey]) ?? 0,
      );

  final String method;
  final String status;
  final int walletUsed;
}

/// `coupon`.
class OrderCouponModel {
  const OrderCouponModel({required this.code, this.discount = 0});

  static const String codeKey = 'code';
  static const String discountKey = 'discount';

  static OrderCouponModel? tryParse(Map<String, dynamic> json) {
    final code = JsonRead.string(json[codeKey]);
    if (code == null) return null;
    return OrderCouponModel(
      code: code,
      discount: JsonRead.integer(json[discountKey]) ?? 0,
    );
  }

  final String code;
  final int discount;
}

/// `loyalty`.
class OrderLoyaltyModel {
  const OrderLoyaltyModel({
    this.pointsRedeemed = 0,
    this.discount = 0,
    this.pointsEarned = 0,
  });

  static const String pointsRedeemedKey = 'pointsRedeemed';
  static const String discountKey = 'discount';
  static const String pointsEarnedKey = 'pointsEarned';

  factory OrderLoyaltyModel.fromJson(Map<String, dynamic> json) =>
      OrderLoyaltyModel(
        pointsRedeemed: JsonRead.integer(json[pointsRedeemedKey]) ?? 0,
        discount: JsonRead.integer(json[discountKey]) ?? 0,
        pointsEarned: JsonRead.integer(json[pointsEarnedKey]) ?? 0,
      );

  final int pointsRedeemed;
  final int discount;
  final int pointsEarned;
}
