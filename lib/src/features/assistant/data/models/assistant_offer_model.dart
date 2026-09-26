import '../../../../core/data/models/json_read.dart';
import '../../../../core/error/exceptions.dart';

/// One row of an `offers` block (the `GET /v1/offers` shape). Only what the
/// card and the core `OfferEntity` use is read; the marketing feature's DTO
/// stays private to it.
class AssistantOfferModel {
  const AssistantOfferModel({
    required this.id,
    this.name = '',
    this.description = '',
    this.triggerType = '',
    this.triggerMin = 0,
    this.triggerMinQuantity = 0,
    this.rewardType = '',
    this.rewardPercent = 0,
    this.rewardMaxDiscount,
    this.rewardAmount = 0,
    this.rewardQuantity = 0,
    this.stackable = false,
    this.endsAt,
  });

  static const String mongoIdKey = '_id';
  static const String idKey = 'id';
  static const String nameKey = 'name';
  static const String descriptionKey = 'description';
  static const String triggerKey = 'trigger';
  static const String rewardKey = 'reward';
  static const String typeKey = 'type';
  static const String minKey = 'min';
  static const String minQuantityKey = 'minQuantity';
  static const String percentKey = 'percent';
  static const String maxDiscountKey = 'maxDiscount';
  static const String amountKey = 'amount';
  static const String quantityKey = 'quantity';
  static const String stackableKey = 'stackable';
  static const String endsAtKey = 'endsAt';

  final String id;
  final String name;
  final String description;
  final String triggerType;
  final int triggerMin;
  final int triggerMinQuantity;
  final String rewardType;
  final int rewardPercent;
  final int? rewardMaxDiscount;
  final int rewardAmount;
  final int rewardQuantity;
  final bool stackable;
  final DateTime? endsAt;

  factory AssistantOfferModel.fromJson(Map<String, dynamic> json) {
    final id =
        JsonRead.string(json[mongoIdKey]) ?? JsonRead.string(json[idKey]);
    if (id == null) throw const ParsingException('offer: id missing');
    final trigger = JsonRead.object(json[triggerKey]) ?? const {};
    final reward = JsonRead.object(json[rewardKey]) ?? const {};
    return AssistantOfferModel(
      id: id,
      name: JsonRead.string(json[nameKey]) ?? '',
      // Optional on the wire: the 4th live offer has none.
      description: JsonRead.string(json[descriptionKey]) ?? '',
      triggerType: JsonRead.string(trigger[typeKey]) ?? '',
      triggerMin: JsonRead.integer(trigger[minKey]) ?? 0,
      triggerMinQuantity: JsonRead.integer(trigger[minQuantityKey]) ?? 0,
      rewardType: JsonRead.string(reward[typeKey]) ?? '',
      rewardPercent: JsonRead.integer(reward[percentKey]) ?? 0,
      rewardMaxDiscount: JsonRead.integer(reward[maxDiscountKey]),
      rewardAmount: JsonRead.integer(reward[amountKey]) ?? 0,
      rewardQuantity: JsonRead.integer(reward[quantityKey]) ?? 0,
      stackable: JsonRead.flag(json[stackableKey]),
      endsAt: JsonRead.dateTime(json[endsAtKey]),
    );
  }
}
