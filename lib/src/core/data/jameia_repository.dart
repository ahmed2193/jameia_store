import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show ValueNotifier, compute;
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:shared_preferences/shared_preferences.dart';

import 'jameia/jameia_loader.dart';
import 'jameia/jameia_models.dart';
import 'models/models.dart';

/// In-memory repository backed by bundled data.
///
/// The commerce catalogue (categories → sub-categories → ranks → products,
/// featured sections, VIP/Mart pricing) comes from the real **Jameia** export,
/// slimmed offline by `tool/build_jameia_asset.js` into a single ~2MB asset
/// (`assets/data/jameia/jameia_catalog.json`) that is parsed **in an isolate**
/// at boot. Account-side data (user / addresses / coupons / orders) and the home
/// reference modules (gathering carousel / tiles / sticky benefits / popups)
/// still come from `assets/data/jameia_data.json`.
///
/// Registered as a lazy singleton; call [load] during bootstrap before the first
/// screen reads data.
class JameiaRepository {
  JameiaRepository();

  // ── Jameia catalogue ──────────────────────────────────────────────────────
  JameiaCatalog _catalog = const JameiaCatalog();

  /// Active store mode. `true` → VIP pricing, `false` → Mart. Toggling it does
  /// NOT mutate the catalogue (each [Product] carries both prices); UI reads the
  /// effective price via `product.priceFor(isVip.value)`.
  final ValueNotifier<bool> isVip = ValueNotifier<bool>(false);

  // ── Account-side ──────────────────────────────────────────────────────────
  late UserProfile _user;
  List<JameiaAddress> _addresses = const [];
  List<Coupon> _coupons = const [];
  List<JameiaOrder> _orders = const [];

  /// Orders the user placed on-device (persisted separately from the seed so we
  /// can prepend them on top of the bundled demo orders on each launch).
  List<JameiaOrder> _userOrders = const [];

  // ── Active address + region (mirrors Jameia's homeSelectedUserAddress +
  //    com.jameia.home.locate.changed / com.jameia.changed.region broadcasts) ────

  /// The currently-selected delivery address id, or null (falls back to the
  /// default address). The home bar / checkout LISTEN to this so picking an
  /// address anywhere repaints them.
  final ValueNotifier<String?> activeAddressIdNotifier = ValueNotifier<String?>(
    null,
  );

  /// Two-letter active region code (`KW` by default). Switching it broadcasts a
  /// region change.
  final ValueNotifier<String> activeRegionNotifier = ValueNotifier<String>(
    'KW',
  );

  /// Last map-picked coordinate ("Last selected location" in the inline sheet).
  LatLng? _lastSelectedLatLng;

  // ── Home reference modules (always from jameia_data.json) ───────────────────
  List<GatheringCard> _gatheringCards = const [];
  List<HomeTile> _homeTiles = const [];
  List<BenefitItem> _benefits = const [];
  List<HomePopup> _homePopups = const [];

  // Fallback catalogue (only used if the jameia asset fails to parse).
  List<Shop> _fallbackShops = const [];
  List<KingKongItem> _fallbackKingkong = const [];
  List<HomeBanner> _fallbackBanners = const [];
  List<String> _fallbackFilters = const [];

  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;

    // Account-side + home reference modules from jameia_data.json.
    final raw = await rootBundle.loadString('assets/data/jameia_data.json');
    final j = json.decode(raw) as Map<String, dynamic>;

    _user = UserProfile.fromJson(j['user'] as Map<String, dynamic>);
    _addresses = (j['addresses'] as List)
        .map((e) => JameiaAddress.fromJson(e as Map<String, dynamic>))
        .toList();
    // Overlay any locally-persisted address book (user adds/edits/deletes)
    // saved via shared_preferences — these survive across app launches.
    await _restoreAddresses();
    _coupons = (j['coupons'] as List)
        .map((e) => Coupon.fromJson(e as Map<String, dynamic>))
        .toList();
    _orders = (j['orders'] as List)
        .map((e) => JameiaOrder.fromJson(e as Map<String, dynamic>))
        .toList();
    // Overlay locally-persisted orders the user placed (newest first, on top of
    // the bundled demo orders).
    await _restoreOrders();
    if (_userOrders.isNotEmpty) _orders = [..._userOrders, ..._orders];

    final home = j['home'] as Map<String, dynamic>?;
    if (home != null) {
      _gatheringCards =
          (home['gatheringCards'] as List?)
              ?.map((e) => GatheringCard.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [];
      _homeTiles =
          (home['tiles'] as List?)
              ?.map((e) => HomeTile.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [];
      _benefits =
          (home['benefits'] as List?)
              ?.map((e) => BenefitItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [];
      _homePopups =
          (home['popups'] as List?)
              ?.map((e) => HomePopup.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [];
    }

    // Keep the jameia_data catalogue blocks as a last-resort fallback.
    _fallbackShops = (j['shops'] as List? ?? const [])
        .map((e) => Shop.fromJson(e as Map<String, dynamic>))
        .toList();
    _fallbackKingkong = (j['kingkong'] as List? ?? const [])
        .map((e) => KingKongItem.fromJson(e as Map<String, dynamic>))
        .toList();
    _fallbackBanners = (j['banners'] as List? ?? const [])
        .map((e) => HomeBanner.fromJson(e as Map<String, dynamic>))
        .toList();
    _fallbackFilters = (j['filters'] as List? ?? const []).cast<String>();

    // Jameia catalogue — heavy decode + build runs off the main thread.
    try {
      final assetRaw = await rootBundle.loadString(
        'assets/data/jameia/jameia_catalog.json',
      );
      _catalog = await compute(parseJameiaCatalog, assetRaw);
    } catch (_) {
      _catalog = const JameiaCatalog(); // fall back to jameia_data below
    }

    _loaded = true;
  }

  // ── Jameia accessors (the new home + shop surfaces) ────────────────────────
  List<JameiaCategory> get categories => _catalog.categories;
  List<FeaturedSection> get sections => _catalog.sections;
  JameiaSettings get settings => _catalog.settings;
  List<Product> get promoProducts => _catalog.promoProducts;
  JameiaCategory? categoryById(String id) => _catalog.categoryById(id);

  /// Where a product (by sku) lives in the taxonomy — used to deep-link a home
  /// featured product to its real shop + sub-category tab + rank.
  ProductLocation? locationOfSku(String sku) => _catalog.productLocation[sku];

  /// VIP/Mart card content for the active mode.
  VipCard get modeCard => isVip.value ? settings.vip : settings.mart;

  // ── Back-compat accessors (search / favorites / order surfaces) ────────────
  UserProfile get user => _user;
  List<KingKongItem> get kingkong =>
      _catalog.kingkong.isNotEmpty ? _catalog.kingkong : _fallbackKingkong;
  List<HomeBanner> get banners =>
      _catalog.banners.isNotEmpty ? _catalog.banners : _fallbackBanners;
  List<String> get filters =>
      _catalog.filters.isNotEmpty ? _catalog.filters : _fallbackFilters;
  List<Shop> get shops =>
      _catalog.shops.isNotEmpty ? _catalog.shops : _fallbackShops;
  List<JameiaAddress> get addresses => _addresses;
  List<Coupon> get coupons => _coupons;
  List<JameiaOrder> get orders => _orders;

  /// Featured-section names exposed as "channels" (home channel strip).
  List<({String id, String name})> get features => [
    for (final s in sections) (id: s.id, name: s.displayName),
  ];

  List<GatheringCard> get gatheringCards => _gatheringCards;
  List<HomeTile> get homeTiles => _homeTiles;
  List<BenefitItem> get benefits => _benefits;
  List<HomePopup> get homePopups => _homePopups;

  /// Promoted shops for the home shop-banner rail (sponsored first, else top).
  List<Shop> get bannerRail {
    final promoted = shops.where((s) => s.sponsored).toList(growable: false);
    return (promoted.isNotEmpty ? promoted : shops)
        .take(8)
        .toList(growable: false);
  }

  List<Product> get allProducts => _catalog.allProducts.isNotEmpty
      ? _catalog.allProducts
      : shops.expand((s) => s.allProducts).toList();

  /// The [Shop] with [id], or null when the catalogue has no such shop. Data
  /// sources throw / return a failure on null; screens render a not-found state
  /// (previously this silently returned `shops.first` — a wrong shop).
  Shop? shopById(String id) {
    for (final s in shops) {
      if (s.id == id) return s;
    }
    return null;
  }

  Product? productById(String id) => _catalog.productsBySku[id] ?? _byScan(id);

  Product? _byScan(String id) {
    for (final p in allProducts) {
      if (p.id == id) return p;
    }
    return null;
  }

  JameiaOrder orderById(String id) => _orders.firstWhere((o) => o.id == id);

  /// A unique id for a freshly-placed order (timestamp-based → never collides
  /// with the seeded `o1..oN` demo orders).
  String nextOrderId() => 'o${DateTime.now().millisecondsSinceEpoch}';

  /// Commit a freshly-placed order: prepend to the live list + persist so it
  /// survives restarts. Mirrors the address-book persistence pattern.
  JameiaOrder addOrder(JameiaOrder o) {
    _userOrders = [o, ..._userOrders];
    _orders = [o, ..._orders];
    unawaited(_persistOrders());
    return o;
  }

  /// The default address, or a benign empty placeholder ([JameiaAddress.empty])
  /// when the book is empty — never throws (Home/Checkout/Orders read this).
  JameiaAddress get defaultAddress {
    if (_addresses.isEmpty) return JameiaAddress.empty;
    return _addresses.firstWhere(
      (a) => a.isDefault,
      orElse: () => _addresses.first,
    );
  }

  // ── Active-address API ──────────────────────────────────────────────────────

  /// The active address id (selected), or null.
  String? get activeAddressId => activeAddressIdNotifier.value;

  /// The active address — the selected one if any, else the default address.
  JameiaAddress get activeAddress {
    final id = activeAddressIdNotifier.value;
    if (id != null) {
      for (final a in _addresses) {
        if (a.id == id) return a;
      }
    }
    return defaultAddress;
  }

  /// Select the active delivery address (== homeSelectedUserAddress + broadcast).
  /// Also records its coordinate as the last-selected location.
  void selectActiveAddress(String id) {
    for (final a in _addresses) {
      if (a.id == id) {
        _lastSelectedLatLng = LatLng(a.lat, a.lng);
        break;
      }
    }
    activeAddressIdNotifier.value = id;
  }

  /// Insert or update an address (`saveOrUpdateV2`); mutates the list, records
  /// its coordinate, and returns the saved address.
  JameiaAddress upsertAddress(JameiaAddress a) {
    final list = [..._addresses];
    final i = list.indexWhere((e) => e.id == a.id);
    if (i >= 0) {
      list[i] = a;
    } else {
      list.add(a);
    }
    _addresses = list;
    _lastSelectedLatLng = LatLng(a.lat, a.lng);
    unawaited(_persistAddresses());
    return a;
  }

  /// Delete an address by id (`DELUSERADDRESS`); clears the active selection if
  /// it pointed at the deleted row.
  ///
  /// Invariant: the address book is never emptied — the last remaining address
  /// is kept. `defaultAddress`/`activeAddress` (and Home/Checkout/Orders that
  /// read them) assume a non-empty book, and an empty persisted book would also
  /// be silently discarded on restart; keeping one address avoids both.
  void deleteAddress(String id) {
    if (_addresses.length <= 1) return;
    _addresses = _addresses.where((a) => a.id != id).toList(growable: false);
    if (activeAddressIdNotifier.value == id) {
      activeAddressIdNotifier.value = null;
    }
    unawaited(_persistAddresses());
  }

  // ── Local persistence (shared_preferences) ──────────────────────────────────

  static const String _kAddrPrefsKey = 'jameia.addressbook.v1';

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
          .map((e) => JameiaAddress.fromJson(e as Map<String, dynamic>))
          .toList();
      if (list.isNotEmpty) _addresses = list;
    } catch (_) {
      /* keep the bundled seed on any decode error */
    }
  }

  static const String _kOrdersPrefsKey = 'jameia.orders.v1';

  /// Write the user-placed orders to local storage.
  Future<void> _persistOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kOrdersPrefsKey,
        json.encode(_userOrders.map((o) => o.toJson()).toList()),
      );
    } catch (_) {
      /* best-effort: never block the UI on persistence */
    }
  }

  /// Restore the locally-persisted user orders, if any.
  Future<void> _restoreOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kOrdersPrefsKey);
      if (saved == null) return;
      _userOrders = (json.decode(saved) as List)
          .map((e) => JameiaOrder.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      /* keep empty on any decode error */
    }
  }

  /// Last map-picked coordinate, or null (the inline sheet's "Last selected").
  LatLng? get lastSelectedLatLng => _lastSelectedLatLng;

  /// Recipient name/phone suggestions derived from saved addresses
  /// (`getnamephonelist`), deduped by phone.
  List<({String name, String phone})> get contactSuggestions {
    final seen = <String>{};
    final out = <({String name, String phone})>[];
    for (final a in _addresses) {
      final phone = a.phone.trim();
      if (phone.isEmpty || !seen.add(phone)) continue;
      out.add((name: a.recipient.trim(), phone: phone));
    }
    return out;
  }

  /// The active two-letter region code.
  String get activeRegion => activeRegionNotifier.value;

  /// Commit a region switch (`switchRegion` + com.jameia.changed.region). No real
  /// auth/logout in the clone.
  void switchRegion(String region2Letter) {
    activeRegionNotifier.value = region2Letter;
  }

  List<Shop> get restaurants =>
      shops.where((s) => s.isRestaurant).toList(growable: false);

  List<Shop> get groceries =>
      shops.where((s) => !s.isRestaurant).toList(growable: false);

  /// Naive product/shop search across names + tags.
  List<Shop> searchShops(String q) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) return shops;
    return shops
        .where(
          (s) =>
              s.name.toLowerCase().contains(query) ||
              s.tags.any((t) => t.toLowerCase().contains(query)) ||
              s.allProducts.any((p) => p.name.toLowerCase().contains(query)),
        )
        .toList(growable: false);
  }
}
