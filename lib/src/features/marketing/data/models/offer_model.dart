import '../../../../core/data/models/json_read.dart';
import '../../../../core/error/exceptions.dart';

/// One row of `GET /v1/offers` → `results.data[]`. `trigger` and `reward` are
/// unions on their `type`; this DTO is their flat superset and the mapper
/// picks the enum. Money is fils.
class OfferModel {
  const OfferModel({
    required this.id,
    this.name = '',
    this.description = '',
    this.status = activeStatus,
    this.triggerType = '',
    this.triggerMin = 0,
    this.triggerMinQuantity = 0,
    this.rewardType = '',
    this.rewardPercent = 0,
    this.rewardMaxDiscount,
    this.rewardAmount = 0,
    this.rewardQuantity = 0,
    this.priority = 0,
    this.stackable = false,
    this.endsAt,
  });

  static const String mongoIdKey = '_id';
  static const String idKey = 'id';
  static const String nameKey = 'name';
  static const String descriptionKey = 'description';
  static const String statusKey = 'status';
  static const String triggerKey = 'trigger';
  static const String rewardKey = 'reward';
  static const String typeKey = 'type';
  static const String minKey = 'min';
  static const String minQuantityKey = 'minQuantity';
  static const String percentKey = 'percent';
  static const String maxDiscountKey = 'maxDiscount';
  static const String amountKey = 'amount';
  static const String quantityKey = 'quantity';
  static const String priorityKey = 'priority';
  static const String stackableKey = 'stackable';
  static const String endsAtKey = 'endsAt';
  static const String activeStatus = 'active';

  /// Throws [ParsingException] without an id.
  factory OfferModel.fromJson(Map<String, dynamic> json) {
    final id =
        JsonRead.string(json[mongoIdKey]) ?? JsonRead.string(json[idKey]);
    if (id == null) throw const ParsingException('offer: id missing');
    final trigger =
        JsonRead.object(json[triggerKey]) ?? const <String, dynamic>{};
    final reward =
        JsonRead.object(json[rewardKey]) ?? const <String, dynamic>{};
    return OfferModel(
      id: id,
      name: JsonRead.string(json[nameKey]) ?? '',
      description: JsonRead.string(json[descriptionKey]) ?? '',
      status: JsonRead.string(json[statusKey]) ?? activeStatus,
      triggerType: JsonRead.string(trigger[typeKey]) ?? '',
      triggerMin: JsonRead.integer(trigger[minKey]) ?? 0,
      triggerMinQuantity: JsonRead.integer(trigger[minQuantityKey]) ?? 0,
      rewardType: JsonRead.string(reward[typeKey]) ?? '',
      rewardPercent: JsonRead.integer(reward[percentKey]) ?? 0,
      rewardMaxDiscount: JsonRead.integer(reward[maxDiscountKey]),
      rewardAmount: JsonRead.integer(reward[amountKey]) ?? 0,
      rewardQuantity: JsonRead.integer(reward[quantityKey]) ?? 0,
      priority: JsonRead.integer(json[priorityKey]) ?? 0,
      stackable: JsonRead.flag(json[stackableKey]),
      endsAt: JsonRead.dateTime(json[endsAtKey]),
    );
  }

  final String id;
  final String name;
  final String description;

  /// `active` | `scheduled` | `inactive` | `expired` | `archived`.
  final String status;

  /// `cart_subtotal` | `item_quantity` | `category_quantity`.
  final String triggerType;
  final int triggerMin;
  final int triggerMinQuantity;

  /// `free_delivery` | `percentage_discount` | `fixed_discount` | `free_product`.
  final String rewardType;
  final int rewardPercent;
  final int? rewardMaxDiscount;
  final int rewardAmount;
  final int rewardQuantity;
  final int priority;
  final bool stackable;
  final DateTime? endsAt;
}
