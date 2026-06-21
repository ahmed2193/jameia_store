import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'models/models.dart';

/// In-memory dummy-data repository. Loads `assets/data/keeta_data.json` once at
/// startup and serves typed models to every feature. Stands in for the real
/// KeeTa REST backend so the clone runs fully offline.
///
/// Registered as a lazy singleton in the service locator; call [load] during
/// bootstrap before the first screen reads data.
class KeetaRepository {
  KeetaRepository();

  late UserProfile _user;
  List<KingKongItem> _kingkong = const [];
  List<HomeBanner> _banners = const [];
  List<String> _filters = const [];
  List<Shop> _shops = const [];
  List<KeetaAddress> _addresses = const [];
  List<Coupon> _coupons = const [];
  List<KeetaOrder> _orders = const [];
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('assets/data/keeta_data.json');
    final j = json.decode(raw) as Map<String, dynamic>;

    _user = UserProfile.fromJson(j['user'] as Map<String, dynamic>);
    _kingkong = (j['kingkong'] as List)
        .map((e) => KingKongItem.fromJson(e as Map<String, dynamic>))
        .toList();
    _banners = (j['banners'] as List)
        .map((e) => HomeBanner.fromJson(e as Map<String, dynamic>))
        .toList();
    _filters = (j['filters'] as List).cast<String>();
    _shops = (j['shops'] as List)
        .map((e) => Shop.fromJson(e as Map<String, dynamic>))
        .toList();
    _addresses = (j['addresses'] as List)
        .map((e) => KeetaAddress.fromJson(e as Map<String, dynamic>))
        .toList();
    _coupons = (j['coupons'] as List)
        .map((e) => Coupon.fromJson(e as Map<String, dynamic>))
        .toList();
    _orders = (j['orders'] as List)
        .map((e) => KeetaOrder.fromJson(e as Map<String, dynamic>))
        .toList();
    _loaded = true;
  }

  // ── Read accessors ──────────────────────────────────────────────────────────
  UserProfile get user => _user;
  List<KingKongItem> get kingkong => _kingkong;
  List<HomeBanner> get banners => _banners;
  List<String> get filters => _filters;
  List<Shop> get shops => _shops;
  List<KeetaAddress> get addresses => _addresses;
  List<Coupon> get coupons => _coupons;
  List<KeetaOrder> get orders => _orders;

  Shop shopById(String id) => _shops.firstWhere((s) => s.id == id);

  KeetaOrder orderById(String id) => _orders.firstWhere((o) => o.id == id);

  KeetaAddress get defaultAddress =>
      _addresses.firstWhere((a) => a.isDefault, orElse: () => _addresses.first);

  List<Shop> get restaurants =>
      _shops.where((s) => s.isRestaurant).toList(growable: false);

  List<Shop> get groceries =>
      _shops.where((s) => !s.isRestaurant).toList(growable: false);

  /// Naive product/shop search across names + tags.
  List<Shop> searchShops(String q) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) return _shops;
    return _shops
        .where((s) =>
            s.name.toLowerCase().contains(query) ||
            s.tags.any((t) => t.toLowerCase().contains(query)) ||
            s.allProducts.any((p) => p.name.toLowerCase().contains(query)))
        .toList(growable: false);
  }
}
