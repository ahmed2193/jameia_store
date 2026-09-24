import '../../../../core/data/models/json_read.dart';
import '../../../../core/error/exceptions.dart';

/// `results` of `GET /v1/subscription-plans`:
/// `{ data: [Plan], enabled, perks: { freeDelivery, pointsMultiplier, discountPercent } }`.
class ProProgramModel {
  const ProProgramModel({
    this.enabled = false,
    this.freeDelivery = false,
    this.pointsMultiplier = 1,
    this.discountPercent = 0,
    this.plans = const <ProPlanModel>[],
  });

  static const String dataKey = 'data';
  static const String enabledKey = 'enabled';
  static const String perksKey = 'perks';
  static const String freeDeliveryKey = 'freeDelivery';
  static const String pointsMultiplierKey = 'pointsMultiplier';
  static const String discountPercentKey = 'discountPercent';
  static const String _logName = 'ProProgramModel';

  /// A malformed plan row is skipped; missing blocks keep their defaults.
  factory ProProgramModel.fromJson(Map<String, dynamic> json) {
    final perks = JsonRead.object(json[perksKey]) ?? const <String, dynamic>{};
    return ProProgramModel(
      enabled: JsonRead.flag(json[enabledKey]),
      freeDelivery: JsonRead.flag(perks[freeDeliveryKey]),
      pointsMultiplier: JsonRead.integer(perks[pointsMultiplierKey]) ?? 1,
      discountPercent: JsonRead.integer(perks[discountPercentKey]) ?? 0,
      plans: JsonRead.rows(
        json[dataKey],
        ProPlanModel.fromJson,
        logName: _logName,
      ),
    );
  }

  final bool enabled;
  final bool freeDelivery;
  final int pointsMultiplier;
  final int discountPercent;
  final List<ProPlanModel> plans;
}

/// One plan row: `{ _id, slug, name, interval, intervalCount, price, sortOrder }`.
class ProPlanModel {
  const ProPlanModel({
    required this.id,
    this.slug = '',
    this.name = '',
    this.interval = '',
    this.intervalCount = 1,
    this.price = 0,
    this.sortOrder = 0,
  });

  static const String mongoIdKey = '_id';
  static const String idKey = 'id';
  static const String slugKey = 'slug';
  static const String nameKey = 'name';
  static const String intervalKey = 'interval';
  static const String intervalCountKey = 'intervalCount';
  static const String priceKey = 'price';
  static const String sortOrderKey = 'sortOrder';

  /// Throws [ParsingException] without an id: it is what `subscribe` sends.
  factory ProPlanModel.fromJson(Map<String, dynamic> json) {
    final id =
        JsonRead.string(json[mongoIdKey]) ?? JsonRead.string(json[idKey]);
    if (id == null) throw const ParsingException('pro plan: id missing');
    return ProPlanModel(
      id: id,
      slug: JsonRead.string(json[slugKey]) ?? '',
      name: JsonRead.string(json[nameKey]) ?? '',
      interval: JsonRead.string(json[intervalKey]) ?? '',
      intervalCount: JsonRead.integer(json[intervalCountKey]) ?? 1,
      price: JsonRead.integer(json[priceKey]) ?? 0,
      sortOrder: JsonRead.integer(json[sortOrderKey]) ?? 0,
    );
  }

  final String id;
  final String slug;
  final String name;

  /// `month` | `year` (wire value).
  final String interval;
  final int intervalCount;

  /// Fils.
  final int price;
  final int sortOrder;
}
