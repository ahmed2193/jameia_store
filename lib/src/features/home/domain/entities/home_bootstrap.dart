import 'package:equatable/equatable.dart';

import 'home_link.dart';

/// How the current order will reach the customer.
enum HomeDeliveryMode { delivery, pickup }

/// When a marketing popup may show again.
enum HomePopupFrequency { session, day }

/// What home needs from the launch snapshot (`GET /v1/init`): where we deliver
/// to (the header), the Pro programme (the Pro banner) and the marketing
/// popups. Home still renders without it — see `GetHomeBootstrapUseCase`.
class HomeBootstrap extends Equatable {
  const HomeBootstrap({
    this.storeName = '',
    this.tagline = '',
    this.delivery,
    this.pro = const HomeProInfo(),
    this.popups = const <HomeMarketingPopup>[],
  });

  static const HomeBootstrap empty = HomeBootstrap();

  final String storeName;
  final String tagline;

  /// `null` until the backend resolved a branch / zone for this customer.
  final HomeDelivery? delivery;
  final HomeProInfo pro;
  final List<HomeMarketingPopup> popups;

  @override
  List<Object?> get props => [storeName, tagline, delivery, pro, popups];
}

/// The delivery context of `init.delivery`: serving branch + the customer's
/// zone (fee, minimum order, ETA). Money is fils.
class HomeDelivery extends Equatable {
  const HomeDelivery({
    this.mode = HomeDeliveryMode.delivery,
    this.branchName = '',
    this.zoneName = '',
    this.etaMinutes = 0,
    this.deliveryFeeFils = 0,
    this.minOrderFils = 0,
    this.expressAvailable = false,
  });

  static const int filsPerDinar = 1000;

  final HomeDeliveryMode mode;
  final String branchName;

  /// `''` when the backend has no zone for the customer yet.
  final String zoneName;
  final int etaMinutes;
  final int deliveryFeeFils;
  final int minOrderFils;
  final bool expressAvailable;

  /// What the header prints after "Deliver to": the zone for a delivery, the
  /// branch for a pickup (and as a fallback).
  String get placeName => mode == HomeDeliveryMode.pickup || zoneName.isEmpty
      ? branchName
      : zoneName;

  bool get hasEta => etaMinutes > 0;
  double get deliveryFeeKd => deliveryFeeFils / filsPerDinar;
  double get minOrderKd => minOrderFils / filsPerDinar;

  /// What a basket of [subtotalKd] is still short of the minimum order, in
  /// fils. The comparison happens in fils because that is what the backend
  /// sends: a subtotal that meets the minimum exactly is exactly zero short,
  /// where the same sum in dinars lands a rounding error above or below it.
  int shortfallFils(double subtotalKd) {
    final missing = minOrderFils - (subtotalKd * filsPerDinar).round();
    return missing > 0 ? missing : 0;
  }

  /// [shortfallFils] as the amount the customer reads.
  double shortfallKd(double subtotalKd) =>
      shortfallFils(subtotalKd) / filsPerDinar;

  @override
  List<Object?> get props => [
    mode,
    branchName,
    zoneName,
    etaMinutes,
    deliveryFeeFils,
    minOrderFils,
    expressAvailable,
  ];
}

/// The Pro membership programme as `init.store.pro` describes it.
class HomeProInfo extends Equatable {
  const HomeProInfo({
    this.enabled = false,
    this.freeDelivery = false,
    this.pointsMultiplier = 1,
    this.discountPercent = 0,
  });

  final bool enabled;
  final bool freeDelivery;
  final int pointsMultiplier;
  final int discountPercent;

  bool get hasPointsBoost => pointsMultiplier > 1;
  bool get hasDiscount => discountPercent > 0;

  @override
  List<Object?> get props => [
    enabled,
    freeDelivery,
    pointsMultiplier,
    discountPercent,
  ];
}

/// A marketing popup of `init.content.popups`. Text arrives already resolved
/// for the request language.
class HomeMarketingPopup extends Equatable {
  const HomeMarketingPopup({
    required this.id,
    this.title = '',
    this.body = '',
    this.imageUrl = '',
    this.ctaLabel = '',
    this.link = HomeLink.none,
    this.frequency = HomePopupFrequency.session,
  });

  final String id;
  final String title;
  final String body;
  final String imageUrl;
  final String ctaLabel;
  final HomeLink link;
  final HomePopupFrequency frequency;

  bool get hasImage => imageUrl.isNotEmpty;

  @override
  List<Object?> get props => [
    id,
    title,
    body,
    imageUrl,
    ctaLabel,
    link,
    frequency,
  ];
}
