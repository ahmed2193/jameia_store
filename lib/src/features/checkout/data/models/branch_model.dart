import '../../../../core/data/models/json_read.dart';
import '../../../../core/error/exceptions.dart';

/// `GET /v1/delivery/branches` → `data[]`.
class BranchModel {
  const BranchModel({
    required this.id,
    this.name = '',
    this.code = '',
    this.address = '',
    this.phone = '',
    this.lat,
    this.lng,
    this.delivery = false,
    this.pickup = false,
    this.express = false,
    this.minOrder = 0,
    this.etaMinutes,
  });

  static const String mongoIdKey = '_id';
  static const String idKey = 'id';
  static const String nameKey = 'name';
  static const String codeKey = 'code';
  static const String addressKey = 'address';
  static const String phoneKey = 'phone';
  static const String latKey = 'lat';
  static const String lngKey = 'lng';
  static const String servicesKey = 'services';
  static const String deliveryKey = 'delivery';
  static const String pickupKey = 'pickup';
  static const String expressKey = 'express';
  static const String minOrderKey = 'minOrder';
  static const String etaMinutesKey = 'etaMinutes';

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    final id =
        JsonRead.string(json[mongoIdKey]) ?? JsonRead.string(json[idKey]);
    if (id == null) throw const ParsingException('branch: id missing');
    final services = JsonRead.object(json[servicesKey]);
    return BranchModel(
      id: id,
      name: JsonRead.string(json[nameKey]) ?? '',
      code: JsonRead.string(json[codeKey]) ?? '',
      address: JsonRead.string(json[addressKey]) ?? '',
      phone: JsonRead.string(json[phoneKey]) ?? '',
      lat: JsonRead.decimal(json[latKey]),
      lng: JsonRead.decimal(json[lngKey]),
      delivery: services != null && JsonRead.flag(services[deliveryKey]),
      pickup: services != null && JsonRead.flag(services[pickupKey]),
      express: services != null && JsonRead.flag(services[expressKey]),
      minOrder: JsonRead.integer(json[minOrderKey]) ?? 0,
      etaMinutes: JsonRead.integer(json[etaMinutesKey]),
    );
  }

  final String id;
  final String name;
  final String code;
  final String address;
  final String phone;
  final double? lat;
  final double? lng;
  final bool delivery;
  final bool pickup;
  final bool express;
  final int minOrder;
  final int? etaMinutes;
}
