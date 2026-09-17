import 'package:equatable/equatable.dart';

import '../localization/localized_pick.dart';
import 'order_item_entity.dart';
import 'rider_entity.dart';

/// A placed / seeded order (orders list, tracking, invoice, refund, support
/// recent-order card, checkout commit result).
///
/// Carries the raw bilingual shop name + date; visible strings are resolved
/// with [shopNameFor] / [dateFor]. The deterministic dummy-backend getters
/// (derived from [id]) are ported verbatim from the `JameiaOrder` DTO.
class JameiaOrderEntity extends Equatable {
  const JameiaOrderEntity({
    required this.id,
    required this.shopName,
    this.shopNameAr = '',
    this.shopId = '',
    required this.shopLogo,
    required this.status,
    required this.statusStep,
    required this.total,
    required this.date,
    this.dateAr = '',
    this.items = const [],
    this.rider,
  });

  final String id;

  /// English / default shop name.
  final String shopName;

  /// Arabic shop name ('' when absent).
  final String shopNameAr;

  /// Catalogue shop id ('' for seed orders).
  final String shopId;
  final String shopLogo;

  /// delivering | completed | preparing | cancelled.
  final String status;

  /// 1..5 for the tracking stepper.
  final int statusStep;
  final double total;

  /// English / default date label.
  final String date;

  /// Arabic date label ('' when absent).
  final String dateAr;
  final List<OrderItemEntity> items;
  final RiderEntity? rider;

  /// Active-locale shop name (Arabic when `ar*` and non-blank).
  String shopNameFor(String languageCode) =>
      pickLocalized(languageCode, en: shopName, ar: shopNameAr);

  /// Active-locale date label (Arabic when `ar*` and non-blank).
  String dateFor(String languageCode) =>
      pickLocalized(languageCode, en: date, ar: dateAr);

  bool get isActive => status == 'delivering' || status == 'preparing';

  int get itemCount => items.fold(0, (s, i) => s + i.qty);

  /// Copy with an advanced status — drives the simulated live-tracking ticks.
  JameiaOrderEntity copyWith({
    String? status,
    int? statusStep,
    RiderEntity? rider,
  }) => JameiaOrderEntity(
    id: id,
    shopName: shopName,
    shopNameAr: shopNameAr,
    shopId: shopId,
    shopLogo: shopLogo,
    status: status ?? this.status,
    statusStep: statusStep ?? this.statusStep,
    total: total,
    date: date,
    dateAr: dateAr,
    items: items,
    rider: rider ?? this.rider,
  );

  // ── Dummy backend fields (deterministic per order id; offline stubs) ────────
  int get _seed => id.hashCode.abs();

  /// Estimated arrival, minutes (8–35).
  int get etaMinutes => 8 + _seed % 28;

  /// 4-digit contactless delivery handoff code.
  String get deliveryCode => (1000 + _seed % 9000).toString();

  /// Platform / service fee.
  double get platformFee => const [0.250, 0.150, 0.350][_seed % 3];

  /// Drop-off preference.
  String get dropOffMethod => _seed.isEven ? 'hand_to_me' : 'leave_at_spot';

  /// Payment-method selector (0 Apple Pay · 1 Google Pay · 2 cash on
  /// delivery · 3 masked Visa).
  int get paymentMethodCase => _seed % 4;

  /// Payment-method label. Brand names + masked card stay verbatim; the
  /// generic cash-on-delivery label is injected by the caller
  /// (e.g. `'checkout.pay_cod'.tr()`), matching `JameiaOrder.paymentMethod`.
  String paymentMethodLabel({required String cashOnDelivery}) {
    switch (paymentMethodCase) {
      case 0:
        return 'Apple Pay';
      case 1:
        return 'Google Pay';
      case 2:
        return cashOnDelivery;
      default:
        return 'Visa •• 42';
    }
  }

  /// Payment / transaction id.
  String get paymentId => 'KT${100000000 + _seed % 899999999}';

  /// Rider bearing in degrees (snapped to 15°) for marker rotation.
  int get riderHeading => (_seed % 24) * 15;

  @override
  List<Object?> get props => [
    id,
    shopName,
    shopNameAr,
    shopId,
    shopLogo,
    status,
    statusStep,
    total,
    date,
    dateAr,
    items,
    rider,
  ];
}
