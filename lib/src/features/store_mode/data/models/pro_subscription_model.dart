import '../../../../core/data/models/json_read.dart';
import '../../../../core/error/exceptions.dart';

/// The subscription object of `GET / POST /v1/account/subscription` and
/// `POST /v1/account/subscription/cancel`.
class ProSubscriptionModel {
  const ProSubscriptionModel({
    required this.id,
    required this.planId,
    this.planName = '',
    this.interval = '',
    this.intervalCount = 1,
    this.price = 0,
    this.status = '',
    this.currentPeriodEnd,
    this.cancelAtPeriodEnd = false,
  });

  static const String mongoIdKey = '_id';
  static const String idKey = 'id';
  static const String planIdKey = 'planId';
  static const String planNameKey = 'planName';
  static const String intervalKey = 'interval';
  static const String intervalCountKey = 'intervalCount';
  static const String priceKey = 'price';
  static const String statusKey = 'status';
  static const String currentPeriodEndKey = 'currentPeriodEnd';
  static const String cancelAtPeriodEndKey = 'cancelAtPeriodEnd';

  /// Throws [ParsingException] without an id.
  factory ProSubscriptionModel.fromJson(Map<String, dynamic> json) {
    final id =
        JsonRead.string(json[mongoIdKey]) ?? JsonRead.string(json[idKey]);
    if (id == null)
      throw const ParsingException('pro subscription: id missing');
    return ProSubscriptionModel(
      id: id,
      planId: JsonRead.string(json[planIdKey]) ?? '',
      planName: JsonRead.string(json[planNameKey]) ?? '',
      interval: JsonRead.string(json[intervalKey]) ?? '',
      intervalCount: JsonRead.integer(json[intervalCountKey]) ?? 1,
      price: JsonRead.integer(json[priceKey]) ?? 0,
      status: JsonRead.string(json[statusKey]) ?? '',
      currentPeriodEnd: JsonRead.dateTime(json[currentPeriodEndKey]),
      cancelAtPeriodEnd: JsonRead.flag(json[cancelAtPeriodEndKey]),
    );
  }

  final String id;
  final String planId;
  final String planName;
  final String interval;
  final int intervalCount;
  final int price;

  /// `active` | `expired` | `cancelled` (wire value).
  final String status;
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;
}
