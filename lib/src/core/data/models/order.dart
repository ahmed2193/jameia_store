import 'package:easy_localization/easy_localization.dart';

import 'shop.dart' show localizedCatalogName;

/// Order lifecycle models.
class JameiaOrder {
  final String id;
  final String shopName; // English / default
  final String shopNameAr; // Arabic counterpart
  final String shopId; // catalogue shop id (placed orders); '' for seed orders
  final String shopLogo;
  final String status; // delivering | completed | preparing | cancelled
  final int statusStep; // 1..5 for the tracking stepper
  final double total;
  final String date; // English / default
  final String dateAr; // Arabic counterpart
  final List<OrderItem> items;
  final Rider? rider;

  const JameiaOrder({
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
    required this.items,
    required this.rider,
  });

  bool get isActive => status == 'delivering' || status == 'preparing';

  int get itemCount => items.fold(0, (s, i) => s + i.qty);

  /// Locale-aware shop name / date.
  String get displayShopName => localizedCatalogName(shopName, shopNameAr);
  String get displayDate => localizedCatalogName(date, dateAr);

  /// Copy with an advanced status — drives the simulated live-tracking ticks.
  JameiaOrder copyWith({String? status, int? statusStep, Rider? rider}) =>
      JameiaOrder(
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

  /// Payment method label. Brand names + masked card stay verbatim; the generic
  /// "Cash on delivery" is localized.
  String get paymentMethod {
    switch (_seed % 4) {
      case 0:
        return 'Apple Pay';
      case 1:
        return 'Google Pay';
      case 2:
        return 'checkout.pay_cod'.tr();
      default:
        return 'Visa •• 42';
    }
  }

  /// Payment / transaction id.
  String get paymentId => 'KT${100000000 + _seed % 899999999}';

  /// Rider bearing in degrees (snapped to 15°) for marker rotation.
  int get riderHeading => (_seed % 24) * 15;

  factory JameiaOrder.fromJson(Map<String, dynamic> j) => JameiaOrder(
    id: j['id'] as String,
    shopName: j['shopName'] as String? ?? '',
    shopNameAr: j['shopNameAr'] as String? ?? '',
    shopId: j['shopId'] as String? ?? '',
    shopLogo: j['shopLogo'] as String? ?? '',
    status: j['status'] as String? ?? 'completed',
    statusStep: (j['statusStep'] as num?)?.toInt() ?? 1,
    total: (j['total'] as num?)?.toDouble() ?? 0,
    date: j['date'] as String? ?? '',
    dateAr: j['dateAr'] as String? ?? '',
    items:
        (j['items'] as List?)
            ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    rider: j['rider'] == null
        ? null
        : Rider.fromJson(j['rider'] as Map<String, dynamic>),
  );

  /// Persist only the stored fields (the dummy-backend getters recompute from
  /// [id] on read, so they're never serialized).
  Map<String, dynamic> toJson() => {
    'id': id,
    'shopName': shopName,
    if (shopNameAr.isNotEmpty) 'shopNameAr': shopNameAr,
    if (shopId.isNotEmpty) 'shopId': shopId,
    'shopLogo': shopLogo,
    'status': status,
    'statusStep': statusStep,
    'total': total,
    'date': date,
    if (dateAr.isNotEmpty) 'dateAr': dateAr,
    'items': items.map((i) => i.toJson()).toList(),
    if (rider != null) 'rider': rider!.toJson(),
  };
}

class OrderItem {
  final String name; // English / default
  final String nameAr; // Arabic counterpart
  final int qty;
  final double price;

  const OrderItem({
    required this.name,
    this.nameAr = '',
    required this.qty,
    required this.price,
  });

  /// Locale-aware item name.
  String get displayName => localizedCatalogName(name, nameAr);

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
    name: j['name'] as String? ?? '',
    nameAr: j['nameAr'] as String? ?? '',
    qty: (j['qty'] as num?)?.toInt() ?? 1,
    price: (j['price'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    if (nameAr.isNotEmpty) 'nameAr': nameAr,
    'qty': qty,
    'price': price,
  };
}

class Rider {
  final String name;
  final String phone;
  final String vehicle; // motorbike | car

  const Rider({required this.name, required this.phone, required this.vehicle});

  // ── Dummy rider profile (deterministic; offline stubs) ──────────────────────
  int get _seed => name.hashCode.abs();

  /// Rider rating (4.6–4.9).
  double get rating =>
      double.parse((4.6 + (_seed % 4) / 10).toStringAsFixed(1));

  /// Rider review count.
  int get reviews => 120 + _seed % 1880;

  factory Rider.fromJson(Map<String, dynamic> j) => Rider(
    name: j['name'] as String? ?? '',
    phone: j['phone'] as String? ?? '',
    vehicle: j['vehicle'] as String? ?? 'motorbike',
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'vehicle': vehicle,
  };
}
