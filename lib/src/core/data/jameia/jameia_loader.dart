/// Parses the slim bundled Jameia asset (`assets/data/jameia/jameia_catalog.json`,
/// produced by `tool/build_jameia_asset.js`) into the [JameiaCatalog] graph.
///
/// [parseJameiaCatalog] is a TOP-LEVEL function so it can run inside an isolate
/// via `compute(...)` — the JSON decode + object construction (the only heavy
/// boot work) then happens off the main thread; only the finished graph is
/// copied back. The asset uses compact product keys + omits default fields, and
/// references products everywhere by sku, so the graph dedups to one [Product]
/// instance per sku shared across all ranks/sections.
library;

import 'dart:convert';

import '../models/models.dart';
import 'jameia_models.dart';

/// Compact product keys (see build_jameia_asset.js):
///   s=sku n=name a=nameAr p=price v=vip o=old i=img
///   av=available(0) hv=hasVariants(1) m=maxQty d=showDiscount(1) f=firstUnitsQty
JameiaCatalog parseJameiaCatalog(String raw) {
  final root = json.decode(raw) as Map<String, dynamic>;
  final meta = (root['meta'] as Map?)?.cast<String, dynamic>() ?? const {};
  final mediaBase =
      (meta['mediaBase'] as String?) ?? 'https://media.jm3eia.com';

  String url(Object? p) {
    if (p is! String || p.isEmpty) return '';
    return p.startsWith('http') ? p : '$mediaBase$p';
  }

  double dbl(Object? v) =>
      v is num ? v.toDouble() : (v is String ? double.tryParse(v) ?? 0 : 0);
  int integer(Object? v) =>
      v is num ? v.toInt() : (v is String ? int.tryParse(v) ?? 0 : 0);

  // ── products dict ───────────────────────────────────────────────────────────
  final productsBySku = <String, Product>{};
  final rawProducts =
      (root['products'] as Map?)?.cast<String, dynamic>() ?? const {};
  rawProducts.forEach((sku, value) {
    final p = (value as Map).cast<String, dynamic>();
    productsBySku[sku] = Product(
      id: sku,
      name: (p['n'] as String?) ?? '',
      nameAr: (p['a'] as String?) ?? '',
      image: url(p['i']),
      price: dbl(p['p']),
      originalPrice: dbl(p['o']),
      vipPrice: dbl(p['v']),
      available: (p['av'] as num?)?.toInt() != 0,
      maxQty: integer(p['m']),
      showDiscount: (p['d'] as num?)?.toInt() == 1,
      firstUnitsQty: integer(p['f']),
      desc: '',
      soldCount: 0,
      kcal: 0,
    );
  });

  List<Product> resolve(Object? skus) {
    if (skus is! List) return const [];
    final out = <Product>[];
    for (final s in skus) {
      final p = productsBySku[s as String];
      if (p != null) out.add(p);
    }
    return out;
  }

  // ── categories → subs → ranks (+ sku → location index) ───────────────────────
  // productLocation lets a home featured product deep-link to its real shop
  // (top category) + sub-category tab + rank. First occurrence wins.
  final productLocation = <String, ProductLocation>{};
  final categories = <JameiaCategory>[];
  for (final c in (root['categories'] as List? ?? const [])) {
    final cat = (c as Map).cast<String, dynamic>();
    final catId = (cat['id'] as String?) ?? '';
    final subs = <JameiaSubCategory>[];
    for (final s in (cat['subs'] as List? ?? const [])) {
      final sub = (s as Map).cast<String, dynamic>();
      final subId = (sub['id'] as String?) ?? '';
      final ranks = <JameiaRank>[];
      for (final r in (sub['ranks'] as List? ?? const [])) {
        final rk = (r as Map).cast<String, dynamic>();
        final rankId = (rk['id'] as String?) ?? '';
        final prods = resolve(rk['skus']);
        for (final p in prods) {
          productLocation.putIfAbsent(
            p.sku,
            () => ProductLocation(catId, subId, rankId),
          );
        }
        ranks.add(
          JameiaRank(
            id: rankId,
            name: (rk['name'] as String?) ?? '',
            nameAr: (rk['nameAr'] as String?) ?? '',
            image: url(rk['img']),
            count: integer(rk['count']) == 0
                ? prods.length
                : integer(rk['count']),
            products: prods,
          ),
        );
      }
      final direct = resolve(sub['skus']);
      for (final p in direct) {
        productLocation.putIfAbsent(
          p.sku,
          () => ProductLocation(catId, subId, ''),
        );
      }
      subs.add(
        JameiaSubCategory(
          id: subId,
          name: (sub['name'] as String?) ?? '',
          nameAr: (sub['nameAr'] as String?) ?? '',
          image: url(sub['img']),
          banner: url(sub['banner']),
          ranks: ranks,
          directProducts: direct,
        ),
      );
    }
    categories.add(
      JameiaCategory(
        id: catId,
        name: (cat['name'] as String?) ?? '',
        nameAr: (cat['nameAr'] as String?) ?? '',
        image: url(cat['img']),
        subs: subs,
      ),
    );
  }

  // ── featured sections ────────────────────────────────────────────────────────
  final sections = <FeaturedSection>[];
  for (final s in (root['sections'] as List? ?? const [])) {
    final sec = (s as Map).cast<String, dynamic>();
    sections.add(
      FeaturedSection(
        id: (sec['id'] as String?) ?? '',
        name: (sec['name'] as String?) ?? '',
        nameAr: (sec['nameAr'] as String?) ?? '',
        sorting: dbl(sec['sort']),
        slides: [for (final u in (sec['slides'] as List? ?? const [])) url(u)],
        products: resolve(sec['skus']),
      ),
    );
  }
  sections.sort((a, b) => a.sorting.compareTo(b.sorting));

  // ── settings ─────────────────────────────────────────────────────────────────
  final st = (root['settings'] as Map?)?.cast<String, dynamic>() ?? const {};
  VipCard card(Object? v) {
    final m = (v as Map?)?.cast<String, dynamic>() ?? const {};
    return VipCard(
      titleEn: (m['titleEn'] as String?) ?? '',
      titleAr: (m['titleAr'] as String?) ?? '',
      descEn: (m['descEn'] as String?) ?? '',
      descAr: (m['descAr'] as String?) ?? '',
      image: url(m['img']),
    );
  }

  final settings = JameiaSettings(
    prepTime: integer(st['prepTime']),
    displayOrderAgain: st['displayOrderAgain'] == true,
    displayBestSelling: st['displayBestSelling'] == true,
    vip: card(st['vip']),
    mart: card(st['mart']),
  );

  // ── derived back-compat lists (shops / kingkong / banners / filters) ─────────
  final shops = [for (final c in categories) _shopForCategory(c)];
  final kingkong = [
    for (final c in categories.take(10))
      KingKongItem(
        id: c.id,
        title: c.name,
        titleAr: c.nameAr,
        icon: 'grid_view',
        color: '#FFE41F',
        image: c.image,
      ),
  ];
  final banners = [
    for (final c in categories.take(5))
      HomeBanner(
        id: c.id,
        title: c.name,
        titleAr: c.nameAr,
        subtitle: '',
        itemCount: c.allProducts.length,
        image: c.image,
        bg: '#FFE41F',
      ),
  ];

  // Promo collection (Promos surface): products flagged hasPromo, deduped.
  final seen = <String>{};
  final promoProducts = <Product>[];
  for (final sec in sections) {
    for (final p in sec.products) {
      if (p.hasPromo && seen.add(p.id)) promoProducts.add(p);
    }
  }

  final allProducts = productsBySku.values.toList(growable: false);

  return JameiaCatalog(
    settings: settings,
    categories: categories,
    sections: sections,
    productsBySku: productsBySku,
    productLocation: productLocation,
    allProducts: allProducts,
    promoProducts: promoProducts,
    shops: shops,
    kingkong: kingkong,
    banners: banners,
    // Stored as i18n keys, resolved with `.tr()` at the render sites (channel /
    // meal-for-one filter chips) so they switch language reactively.
    filters: const [
      'catalog.filter_recommended',
      'catalog.filter_offers',
      'catalog.filter_best_selling',
      'catalog.filter_new',
      'catalog.filter_free_shipping',
      'catalog.filter_nearby',
    ],
  );
}

/// Derives a back-compat [Shop] for a category: sections = one [MenuSection]
/// per sub-category (so search / favorites / allProducts keep working). Meta
/// (rating / time / fee / distance) is synthesised deterministically from the id.
Shop _shopForCategory(JameiaCategory c) {
  final seed = c.id.hashCode.abs();
  final rating = 4.0 + (seed % 10) / 10.0;
  final ratingCount = 50 + seed % 1450;
  final fee = const [0.0, 0.0, 0.25, 0.5][seed % 4];
  final free = fee == 0.0;
  final time = const [
    '15-25 min',
    '20-30 min',
    '25-35 min',
    '30-45 min',
  ][seed % 4];
  final distance = 0.5 + (seed % 55) / 10.0;
  final minOrder = const [1.0, 2.0, 3.0, 5.0][seed % 4];

  final sections = <MenuSection>[
    for (final s in c.subs)
      if (s.allProducts.isNotEmpty)
        MenuSection(
          id: s.id,
          title: s.name,
          image: s.image,
          products: s.allProducts,
        ),
  ];

  return Shop(
    id: c.id,
    name: c.name,
    nameAr: c.nameAr,
    logo: c.image,
    cover: c.image,
    kind: 'grocery',
    rating: double.parse(rating.toStringAsFixed(1)),
    ratingCount: ratingCount,
    deliveryFee: fee,
    deliveryTime: time,
    distanceKm: double.parse(distance.toStringAsFixed(1)),
    minOrder: minOrder,
    tags: [c.name],
    promo: (seed % 3 == 0)
        ? (free ? 'Free delivery' : '${10 + seed % 30}% off')
        : '',
    freeDelivery: free,
    sponsored: seed % 9 == 0,
    sections: sections,
  );
}
