import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import 'hero/hero_loader.dart';
import 'models/models.dart';

/// In-memory repository backed by bundled data — what is still offline.
///
/// Account-side data (user / addresses / coupons / orders) comes from
/// `assets/data/hero_data.json`. The shop count (the Mine favourites count)
/// comes from the real **Hero** export, slimmed offline by
/// `tool/build_hero_asset.js` into a single ~2MB asset
/// (`assets/data/hero/hero_catalog.json`): counted **in an isolate** the
/// first time it is asked for ([shopCount]), never before the first frame
/// (BX-05 / PB-14), and only the number is kept.
///
/// Registered as a singleton; call [load] during bootstrap before the first
/// screen reads data.
class HeroRepository {
  HeroRepository();

  static const String _catalogAsset = 'assets/data/hero/hero_catalog.json';

  // ── Hero catalogue (only its shop count is read) ───────────────────────────
  Future<int>? _shopCount;
  int? _knownShopCount;

  // ── Account-side ──────────────────────────────────────────────────────────
  late UserProfile _user;
  List<HeroAddress> _addresses = const [];
  List<Coupon> _coupons = const [];
  List<HeroOrder> _orders = const [];

  // Fallback shop list (only used if the Hero asset fails to parse).
  List<Shop> _fallbackShops = const [];

  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;

    // Account-side data from hero_data.json.
    final raw = await rootBundle.loadString('assets/data/hero_data.json');
    final j = json.decode(raw) as Map<String, dynamic>;

    _user = UserProfile.fromJson(j['user'] as Map<String, dynamic>);
    _addresses = (j['addresses'] as List)
        .map((e) => HeroAddress.fromJson(e as Map<String, dynamic>))
        .toList();
    // Overlay any locally-persisted address book saved via shared_preferences.
    await _restoreAddresses();
    _coupons = (j['coupons'] as List)
        .map((e) => Coupon.fromJson(e as Map<String, dynamic>))
        .toList();
    _orders = (j['orders'] as List)
        .map((e) => HeroOrder.fromJson(e as Map<String, dynamic>))
        .toList();
    // Overlay orders placed on-device by older builds (newest first, on top of
    // the bundled demo orders).
    final userOrders = await _restoreOrders();
    if (userOrders.isNotEmpty) _orders = [...userOrders, ..._orders];

    // Keep the hero_data shop block as a last-resort fallback.
    _fallbackShops = (j['shops'] as List? ?? const [])
        .map((e) => Shop.fromJson(e as Map<String, dynamic>))
        .toList();

    _loaded = true;
  }

  UserProfile get user => _user;
  List<HeroAddress> get addresses => _addresses;
  List<Coupon> get coupons => _coupons;
  List<HeroOrder> get orders => _orders;

  /// How many shops the bundled catalogue lists — one per top category, like
  /// the parsed catalogue's `shops`. The 2 MB asset is read uncached and
  /// decoded in an isolate on the first call only (warmed after the first
  /// frame, else the Mine tab), and just the number comes back;
  /// `hero_data`'s shop block counts when the catalogue cannot be read. Once
  /// known, the answer is a fresh future in the caller's zone.
  Future<int> shopCount() {
    final known = _knownShopCount;
    if (known != null) return Future<int>.value(known);
    return _shopCount ??= _countShops().then(
      (count) => _knownShopCount = count,
    );
  }

  Future<int> _countShops() async {
    try {
      final raw = await rootBundle.loadString(_catalogAsset, cache: false);
      final count = await compute(countHeroShops, raw);
      if (count > 0) return count;
    } on Object catch (_) {
      // Unreadable catalogue: the fallback block below.
    }
    return _fallbackShops.length;
  }

  /// The default address, or a benign empty placeholder ([HeroAddress.empty])
  /// when the book is empty — never throws.
  HeroAddress get defaultAddress {
    if (_addresses.isEmpty) return HeroAddress.empty;
    return _addresses.firstWhere(
      (a) => a.isDefault,
      orElse: () => _addresses.first,
    );
  }

  /// The active address. Nothing selects one any more (addresses live on the
  /// API), so it is the default address.
  HeroAddress get activeAddress => defaultAddress;

  /// Insert or update an address (`saveOrUpdateV2`); mutates the list and
  /// returns the saved address.
  HeroAddress upsertAddress(HeroAddress a) {
    final list = [..._addresses];
    final i = list.indexWhere((e) => e.id == a.id);
    if (i >= 0) {
      list[i] = a;
    } else {
      list.add(a);
    }
    _addresses = list;
    unawaited(_persistAddresses());
    return a;
  }

  /// Delete an address by id (`DELUSERADDRESS`).
  ///
  /// Invariant: the address book is never emptied — the last remaining address
  /// is kept. [defaultAddress] assumes a non-empty book, and an empty persisted
  /// book would also be silently discarded on restart; keeping one address
  /// avoids both.
  void deleteAddress(String id) {
    if (_addresses.length <= 1) return;
    _addresses = _addresses.where((a) => a.id != id).toList(growable: false);
    unawaited(_persistAddresses());
  }

  // ── Local persistence (shared_preferences) ──────────────────────────────────

  static const String _kAddrPrefsKey = 'hero.addressbook.v1';

  /// Write the current address book to local storage.
  Future<void> _persistAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kAddrPrefsKey,
        json.encode(_addresses.map((a) => a.toJson()).toList()),
      );
    } catch (_) {
      /* best-effort: never block the UI on persistence */
    }
  }

  /// Replace the seed address book with the locally-persisted one, if any.
  Future<void> _restoreAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kAddrPrefsKey);
      if (saved == null) return;
      final list = (json.decode(saved) as List)
          .map((e) => HeroAddress.fromJson(e as Map<String, dynamic>))
          .toList();
      if (list.isNotEmpty) _addresses = list;
    } catch (_) {
      /* keep the bundled seed on any decode error */
    }
  }

  static const String _kOrdersPrefsKey = 'hero.orders.v1';

  /// The orders older builds placed on-device, if any.
  Future<List<HeroOrder>> _restoreOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kOrdersPrefsKey);
      if (saved == null) return const [];
      return (json.decode(saved) as List)
          .map((e) => HeroOrder.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const []; // keep empty on any decode error
    }
  }
}
