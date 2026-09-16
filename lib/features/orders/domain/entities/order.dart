import 'package:equatable/equatable.dart';

/// Framework-free order entity (owned by the orders feature — no reuse of the
/// core `KeetaOrder` DTO, no `easy_localization` / `intl`).
///
/// Carries the raw bilingual shop name / date so the presentation layer can
/// resolve the active-locale display **live** (see
/// `presentation/util/order_display.dart`). The deterministic dummy-backend
/// getters (offline stubs derived from [id]) are pure Dart and stay on the
/// entity; only the locale-live labels (`displayShopName`, `displayDate`,
/// `paymentMethod`) move to the presentation display extension.
class OrderEntity extends Equatable {
  const OrderEntity({
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

  /// English / default shop name + its Arabic counterpart.
  final String shopName;
  final String shopNameAr;

  /// Catalogue shop id used for shop/reorder navigation. For the order list it
  /// is the *resolved* navigable id (the data layer fills the name-match /
  /// first-shop fallback for seed orders); elsewhere it is the raw value.
  final String shopId;

  final String shopLogo;
  final String status; // delivering | completed | preparing | cancelled
  final int statusStep; // 1..5 for the tracking stepper
  final double total;

  /// English / default date label + its Arabic counterpart.
  final String date;
  final String dateAr;

  final List<OrderItemEntity> items;
  final RiderEntity? rider;

  bool get isActive => status == 'delivering' || status == 'preparing';

  int get itemCount => items.fold(0, (s, i) => s + i.qty);

  /// Copy with an advanced status — drives the simulated live-tracking ticks.
  OrderEntity copyWith({String? status, int? statusStep, RiderEntity? rider}) =>
      OrderEntity(
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

  /// Estimated arrival, minutes.
  int get etaMinutes => 8 + _seed % 28; // 8–35

  /// 4-digit contactless delivery handoff code.
  String get deliveryCode => (1000 + _seed % 9000).toString();

  /// Platform / service fee.
  double get platformFee => const [0.250, 0.150, 0.350][_seed % 3];

  /// Drop-off preference.
  String get dropOffMethod => _seed.isEven ? 'hand_to_me' : 'leave_at_spot';

  /// Payment / transaction id.
  String get paymentId => 'KT${100000000 + _seed % 899999999}';

  /// Rider bearing in degrees (snapped to 15°) for marker rotation.
  int get riderHeading => (_seed % 24) * 15;

  /// The dummy-backend payment-method selector (0..3). The display label is
  /// resolved live in `presentation/util/order_display.dart` because case 2
  /// ("Cash on delivery") is localized.
  int get paymentMethodCase => _seed % 4;

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

/// Framework-free order line item. Carries the raw bilingual name; the
/// locale-live `displayName` lives in the presentation display extension.
class OrderItemEntity extends Equatable {
  const OrderItemEntity({
    required this.name,
    this.nameAr = '',
    required this.qty,
    required this.price,
  });

  final String name; // English / default
  final String nameAr; // Arabic counterpart
  final int qty;
  final double price;

  @override
  List<Object?> get props => [name, nameAr, qty, price];
}

/// Framework-free rider entity. The rating / review getters are deterministic
/// offline stubs (derived from [name]) — pure Dart, so they stay here.
class RiderEntity extends Equatable {
  const RiderEntity({
    required this.name,
    required this.phone,
    required this.vehicle,
  });

  final String name;
  final String phone;
  final String vehicle; // motorbike | car

  int get _seed => name.hashCode.abs();

  /// Rider rating (4.6–4.9).
  double get rating =>
      double.parse((4.6 + (_seed % 4) / 10).toStringAsFixed(1));

  /// Rider review count.
  int get reviews => 120 + _seed % 1880;

  @override
  List<Object?> get props => [name, phone, vehicle];
}
