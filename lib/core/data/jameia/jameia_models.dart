/// Jameia catalogue domain models — the real category → sub-category → rank →
/// product hierarchy captured from `https://api.jm3eia.com/v6`.
///
/// Shape (mirrors the jm3eia data flow):
///   [JameiaCategory] (taxonomy / home grid)
///     └─ [JameiaSubCategory]  → becomes a TAB on the shop screen
///          ├─ [JameiaRank]    → rank-rail section (has products)   | OR
///          └─ directProducts  → plain grid (sub-category with 0 ranks)
///   [FeaturedSection] = a home menu rail ("Offers", "Best sellers", …)
///
/// All products are shared [Product] instances (deduped by sku in the loader),
/// so the same product object appears under every rank/section it belongs to.
/// Every field is a plain primitive / List so the whole graph is sendable across
/// an isolate (built off the main thread in `parseJameiaCatalog`).
library;

import '../models/models.dart';

/// One rank inside a sub-category — the unit of the shop screen's rank rail.
class JameiaRank {
  final String id;
  final String name;
  final String nameAr;
  final String image; // rank thumbnail ('' → rail shows text-only)
  final int count; // backend product count
  final List<Product> products;

  const JameiaRank({
    required this.id,
    required this.name,
    required this.nameAr,
    this.image = '',
    this.count = 0,
    this.products = const [],
  });

  /// Locale-aware rank name (Arabic when the locale is `ar` and available).
  String get displayName => localizedCatalogName(name, nameAr);
}

/// A sub-category = one TAB on the shop (products) screen. Has either ranks
/// (rank rail + sections) or, when [ranks] is empty, a flat product grid.
class JameiaSubCategory {
  final String id;
  final String name;
  final String nameAr;
  final String image;
  final String banner; // optional top-of-tab banner ('' → none)
  final List<JameiaRank> ranks;
  final List<Product> directProducts; // used only when ranks is empty

  const JameiaSubCategory({
    required this.id,
    required this.name,
    required this.nameAr,
    this.image = '',
    this.banner = '',
    this.ranks = const [],
    this.directProducts = const [],
  });

  /// Locale-aware sub-category name (drives the shop sub-tab labels).
  String get displayName => localizedCatalogName(name, nameAr);

  bool get hasRanks => ranks.isNotEmpty;

  List<Product> get allProducts => hasRanks
      ? [for (final r in ranks) ...r.products]
      : directProducts;
}

/// A top-level category = a "shop" entry point on home; opens the shop screen
/// where its [subs] become the tabs.
class JameiaCategory {
  final String id;
  final String name;
  final String nameAr;
  final String image;
  final List<JameiaSubCategory> subs;

  const JameiaCategory({
    required this.id,
    required this.name,
    required this.nameAr,
    this.image = '',
    this.subs = const [],
  });

  /// Locale-aware category name (home category rail / shop title).
  String get displayName => localizedCatalogName(name, nameAr);

  List<Product> get allProducts =>
      [for (final s in subs) ...s.allProducts];
}

/// A featured menu section = one home rail (GET /feature). [slides] are full
/// banner image URLs; [products] are the rail's products.
class FeaturedSection {
  final String id;
  final String name;
  final String nameAr;
  final double sorting;
  final List<String> slides;
  final List<Product> products;

  const FeaturedSection({
    required this.id,
    required this.name,
    required this.nameAr,
    this.sorting = 0,
    this.slides = const [],
    this.products = const [],
  });

  /// Locale-aware section name (home featured-rail title).
  String get displayName => localizedCatalogName(name, nameAr);

  // Special backend section ids.
  bool get isOrderAgain => id == 'order_again';
  bool get isBestSelling => id == 'best_selling';
}

/// Where a product lives in the taxonomy — used to deep-link a home featured
/// product to its real shop (top category) + sub-category tab + rank section.
class ProductLocation {
  final String categoryId; // top-level category (the shop)
  final String subId; // sub-category (the tab)
  final String rankId; // rank ('' when the sub has no ranks)

  const ProductLocation(this.categoryId, this.subId, this.rankId);
}

/// The VIP / Mart hero card content (from `settings.display.content`).
class VipCard {
  final String titleEn;
  final String titleAr;
  final String descEn;
  final String descAr;
  final String image;

  const VipCard({
    this.titleEn = '',
    this.titleAr = '',
    this.descEn = '',
    this.descAr = '',
    this.image = '',
  });

  String get title => titleEn.isNotEmpty ? titleEn : titleAr;
  String get desc => descEn.isNotEmpty ? descEn : descAr;
}

/// Store settings relevant to the Keeta surfaces.
class JameiaSettings {
  final int prepTime; // minutes — VIP/Mart "fast" card
  final bool displayOrderAgain;
  final bool displayBestSelling;
  final VipCard vip;
  final VipCard mart;

  const JameiaSettings({
    this.prepTime = 0,
    this.displayOrderAgain = false,
    this.displayBestSelling = false,
    this.vip = const VipCard(),
    this.mart = const VipCard(),
  });
}

/// Root container produced by the loader (built in an isolate). Carries both the
/// new jameia hierarchy (categories / sections / settings) AND the derived
/// back-compat lists (shops / kingkong / banners / filters / allProducts) that
/// the rest of the app already reads.
class JameiaCatalog {
  final JameiaSettings settings;
  final List<JameiaCategory> categories;
  final List<FeaturedSection> sections;
  final Map<String, Product> productsBySku;
  final Map<String, ProductLocation> productLocation;
  final List<Product> allProducts;
  final List<Product> promoProducts;

  // Derived for the existing Keeta accessors (search / favorites / etc.).
  final List<Shop> shops;
  final List<KingKongItem> kingkong;
  final List<HomeBanner> banners;
  final List<String> filters;

  const JameiaCatalog({
    this.settings = const JameiaSettings(),
    this.categories = const [],
    this.sections = const [],
    this.productsBySku = const {},
    this.productLocation = const {},
    this.allProducts = const [],
    this.promoProducts = const [],
    this.shops = const [],
    this.kingkong = const [],
    this.banners = const [],
    this.filters = const [],
  });

  JameiaCategory? categoryById(String id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }
}
