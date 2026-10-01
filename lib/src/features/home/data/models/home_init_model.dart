import '../../../../core/data/models/json_read.dart';
import '../../../../core/error/exceptions.dart';

/// The part of `GET /v1/init` → `results` home renders: `store` (name,
/// Pro programme, the first-order free-delivery flag), whether `user` is
/// there (the reply was for a signed-in customer), `delivery` (mode, branch,
/// zone) and `content.popups`. The rest of the snapshot (the user's fields,
/// wishlist ids, cart offers, payment, loyalty, the other feature flags)
/// belongs to the features that own it.
class HomeInitModel {
  const HomeInitModel({
    this.storeName = '',
    this.proEnabled = false,
    this.proFreeDelivery = false,
    this.proPointsMultiplier = 1,
    this.proDiscountPercent = 0,
    this.firstOrderFreeDelivery = false,
    this.hasCustomer = false,
    this.delivery,
    this.popups = const <HomePopupModel>[],
  });

  static const String storeKey = 'store';
  static const String nameKey = 'name';
  static const String proKey = 'pro';
  static const String enabledKey = 'enabled';
  static const String perksKey = 'perks';
  static const String freeDeliveryKey = 'freeDelivery';
  static const String pointsMultiplierKey = 'pointsMultiplier';
  static const String discountPercentKey = 'discountPercent';
  static const String featureFlagsKey = 'featureFlags';

  /// `store.featureFlags.firstOrderFreeDelivery` — the backend's off switch
  /// for the welcome gift (`featureFlags` is free-form in the spec): the gift
  /// is on unless the store sends `false`.
  static const String firstOrderFreeDeliveryFlag = 'firstOrderFreeDelivery';
  static const String userKey = 'user';
  static const String deliveryKey = 'delivery';
  static const String contentKey = 'content';
  static const String popupsKey = 'popups';
  static const String _logName = 'HomeInitModel';

  /// Every block is optional: a missing one leaves its defaults.
  factory HomeInitModel.fromJson(Map<String, dynamic> json) {
    final store = JsonRead.object(json[storeKey]) ?? const <String, dynamic>{};
    final pro = JsonRead.object(store[proKey]) ?? const <String, dynamic>{};
    final perks = JsonRead.object(pro[perksKey]) ?? const <String, dynamic>{};
    final flags =
        JsonRead.object(store[featureFlagsKey]) ?? const <String, dynamic>{};
    final content =
        JsonRead.object(json[contentKey]) ?? const <String, dynamic>{};
    return HomeInitModel(
      storeName: JsonRead.string(store[nameKey]) ?? '',
      proEnabled: JsonRead.flag(pro[enabledKey]),
      proFreeDelivery: JsonRead.flag(perks[freeDeliveryKey]),
      proPointsMultiplier: JsonRead.integer(perks[pointsMultiplierKey]) ?? 1,
      proDiscountPercent: JsonRead.integer(perks[discountPercentKey]) ?? 0,
      firstOrderFreeDelivery: JsonRead.flag(
        flags[firstOrderFreeDeliveryFlag],
        fallback: true,
      ),
      hasCustomer: JsonRead.object(json[userKey]) != null,
      delivery: HomeDeliveryModel.tryParse(json[deliveryKey]),
      popups: JsonRead.rows(
        content[popupsKey],
        HomePopupModel.fromJson,
        logName: _logName,
      ),
    );
  }

  final String storeName;
  final bool proEnabled;
  final bool proFreeDelivery;
  final int proPointsMultiplier;
  final int proDiscountPercent;
  final bool firstOrderFreeDelivery;

  /// `user` is an object: the request carried a signed-in customer's token.
  final bool hasCustomer;
  final HomeDeliveryModel? delivery;
  final List<HomePopupModel> popups;
}

/// `results.delivery`: `{ mode, branch{ name … }, zone: null | { name,
/// deliveryFee, minOrder, etaMinutes … } }`. Money is fils.
class HomeDeliveryModel {
  const HomeDeliveryModel({
    this.mode = deliveryMode,
    this.branchName = '',
    this.zoneName = '',
    this.deliveryFee = 0,
    this.minOrder = 0,
    this.etaMinutes = 0,
  });

  static const String modeKey = 'mode';
  static const String branchKey = 'branch';
  static const String zoneKey = 'zone';
  static const String nameKey = 'name';
  static const String deliveryFeeKey = 'deliveryFee';
  static const String minOrderKey = 'minOrder';
  static const String etaMinutesKey = 'etaMinutes';
  static const String deliveryMode = 'delivery';
  static const String pickupMode = 'pickup';

  /// `null` when [raw] is not an object.
  static HomeDeliveryModel? tryParse(Object? raw) {
    final json = JsonRead.object(raw);
    if (json == null) return null;
    final branch = JsonRead.object(json[branchKey]);
    final zone = JsonRead.object(json[zoneKey]);
    return HomeDeliveryModel(
      mode: JsonRead.string(json[modeKey]) ?? deliveryMode,
      branchName: JsonRead.string(branch?[nameKey]) ?? '',
      zoneName: JsonRead.string(zone?[nameKey]) ?? '',
      deliveryFee: JsonRead.integer(zone?[deliveryFeeKey]) ?? 0,
      minOrder: JsonRead.integer(zone?[minOrderKey]) ?? 0,
      etaMinutes: JsonRead.integer(zone?[etaMinutesKey]) ?? 0,
    );
  }

  /// `delivery` | `pickup` (wire value).
  final String mode;
  final String branchName;
  final String zoneName;
  final int deliveryFee;
  final int minOrder;
  final int etaMinutes;
}

/// One row of `results.content.popups`.
class HomePopupModel {
  const HomePopupModel({
    required this.id,
    this.title = '',
    this.body = '',
    this.imageUrl = '',
    this.ctaLabel = '',
    this.linkType = '',
    this.linkTarget = '',
    this.frequency = sessionFrequency,
  });

  static const String idKey = 'id';
  static const String mongoIdKey = '_id';
  static const String titleKey = 'title';
  static const String bodyKey = 'body';
  static const String imageUrlKey = 'imageUrl';
  static const String ctaLabelKey = 'ctaLabel';
  static const String linkTypeKey = 'linkType';
  static const String linkTargetKey = 'linkTarget';
  static const String frequencyKey = 'frequency';
  static const String sessionFrequency = 'session';
  static const String dayFrequency = 'day';

  /// Throws [ParsingException] without an id: the id is what the "shown today"
  /// stamp is stored under.
  factory HomePopupModel.fromJson(Map<String, dynamic> json) {
    final id =
        JsonRead.string(json[idKey]) ?? JsonRead.string(json[mongoIdKey]);
    if (id == null) throw const ParsingException('home popup: id missing');
    return HomePopupModel(
      id: id,
      title: JsonRead.string(json[titleKey]) ?? '',
      body: JsonRead.string(json[bodyKey]) ?? '',
      imageUrl: JsonRead.string(json[imageUrlKey]) ?? '',
      ctaLabel: JsonRead.string(json[ctaLabelKey]) ?? '',
      linkType: JsonRead.string(json[linkTypeKey]) ?? '',
      linkTarget: JsonRead.string(json[linkTargetKey]) ?? '',
      frequency: JsonRead.string(json[frequencyKey]) ?? sessionFrequency,
    );
  }

  final String id;
  final String title;
  final String body;
  final String imageUrl;
  final String ctaLabel;
  final String linkType;
  final String linkTarget;

  /// `session` | `day` (wire value).
  final String frequency;
}
