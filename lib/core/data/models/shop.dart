import 'package:easy_localization/easy_localization.dart';

/// True when the active locale is Arabic — drives the catalogue `displayName`
/// getters below. Reads [Intl.defaultLocale], which `LocalizationCubit` syncs on
/// every language change (the same source `Formatters` uses), so switching the
/// app to Arabic flips every catalogue name to its Arabic value on the next
/// rebuild (easy_localization's `setLocale` rebuilds the tree).
bool get catalogIsArabic => (Intl.defaultLocale ?? 'en').startsWith('ar');

/// Picks the Arabic [ar] name when the locale is Arabic and [ar] is non-empty,
/// otherwise the English [en] name.
String localizedCatalogName(String en, String ar) =>
    catalogIsArabic && ar.trim().isNotEmpty ? ar : en;

/// A styled promotional tag shown on a shop card (home golden feed card / shop
/// meta strip). [style] picks the visual treatment:
///   • `ribbon` — coupon ribbon, `#D90012` bg + top-left 24dp corner (atom `c1cd40`)
///   • `coupon` — pill with dashed/voucher feel
///   • `pill`   — plain rounded chip
class PromoTag {
  final String text;
  final String bg; // hex
  final String fg; // hex
  final String style; // ribbon | coupon | pill

  const PromoTag({
    required this.text,
    this.bg = '#D90012',
    this.fg = '#FFFFFF',
    this.style = 'ribbon',
  });

  factory PromoTag.fromJson(Map<String, dynamic> j) => PromoTag(
        text: j['text'] as String? ?? '',
        bg: j['bg'] as String? ?? '#D90012',
        fg: j['fg'] as String? ?? '#FFFFFF',
        style: j['style'] as String? ?? 'ribbon',
      );
}

/// Shop / restaurant / grocery store and its menu — the central commerce model.
class Shop {
  final String id;
  final String name;
  final String nameAr;
  final String logo;
  final String cover;
  final String kind; // restaurant | grocery
  final double rating;
  final int ratingCount;
  final double deliveryFee;
  final String deliveryTime;
  final double distanceKm;
  final double minOrder;
  final List<String> tags;
  final String promo;
  final bool freeDelivery;
  final bool sponsored;
  final List<MenuSection> sections;

  // ── Reference golden-card extras (seeded; tolerant of older data) ───────────
  /// Styled promo ribbons/coupons rendered on the card (real `c1cd40` ribbon).
  final List<PromoTag> promoTags;
  /// Feature labels (e.g. "Buy 1 Get 1", "Low delivery fee").
  final List<String> featureLabels;
  /// Optional notice/status line (e.g. "Opens at 10:00").
  final String notice;
  /// Whether the shop is currently open (false → dim cover + closed overlay).
  final bool isOpen;

  const Shop({
    required this.id,
    required this.name,
    this.nameAr = '',
    required this.logo,
    required this.cover,
    required this.kind,
    required this.rating,
    required this.ratingCount,
    required this.deliveryFee,
    required this.deliveryTime,
    required this.distanceKm,
    required this.minOrder,
    required this.tags,
    required this.promo,
    required this.freeDelivery,
    required this.sponsored,
    required this.sections,
    this.promoTags = const [],
    this.featureLabels = const [],
    this.notice = '',
    this.isOpen = true,
  });

  bool get isRestaurant => kind == 'restaurant';

  /// Locale-aware shop name (Arabic when the locale is `ar` and available).
  String get displayName => localizedCatalogName(name, nameAr);

  List<Product> get allProducts =>
      sections.expand((s) => s.products).toList(growable: false);

  int get _maxDiscountPercent {
    var m = 0;
    for (final p in allProducts) {
      if (p.discountPercent > m) m = p.discountPercent;
    }
    return m;
  }

  /// Promo tags to render on the golden feed card / shop meta — explicit seeded
  /// [promoTags] when present, otherwise synthesized from shop state so every
  /// shop (including jm3eia-sourced ones) gets reference-style ribbons.
  List<PromoTag> get displayTags {
    if (promoTags.isNotEmpty) return promoTags;
    final out = <PromoTag>[];
    final maxOff = _maxDiscountPercent;
    if (maxOff >= 5) {
      out.add(PromoTag(
          text: 'catalog.up_to_off'.tr(namedArgs: {'percent': '$maxOff'})));
    } else if (promo.isNotEmpty) {
      out.add(PromoTag(text: promo));
    }
    if (freeDelivery) {
      out.add(PromoTag(
          text: 'catalog.free_delivery'.tr(),
          bg: '#E2F6F0',
          fg: '#008C65',
          style: 'coupon'));
    }
    return out;
  }

  /// Feature labels — explicit [featureLabels] when present, else first tags.
  List<String> get displayFeatures =>
      featureLabels.isNotEmpty ? featureLabels : tags.take(2).toList(growable: false);

  factory Shop.fromJson(Map<String, dynamic> j) => Shop(
        id: j['id'] as String,
        name: j['name'] as String,
        nameAr: j['nameAr'] as String? ?? '',
        logo: j['logo'] as String? ?? '',
        cover: j['cover'] as String? ?? '',
        kind: j['kind'] as String? ?? 'restaurant',
        rating: (j['rating'] as num?)?.toDouble() ?? 0,
        ratingCount: (j['ratingCount'] as num?)?.toInt() ?? 0,
        deliveryFee: (j['deliveryFee'] as num?)?.toDouble() ?? 0,
        deliveryTime: j['deliveryTime'] as String? ?? '',
        distanceKm: (j['distanceKm'] as num?)?.toDouble() ?? 0,
        minOrder: (j['minOrder'] as num?)?.toDouble() ?? 0,
        tags: (j['tags'] as List?)?.cast<String>() ?? const [],
        promo: j['promo'] as String? ?? '',
        freeDelivery: j['freeDelivery'] as bool? ?? false,
        sponsored: j['sponsored'] as bool? ?? false,
        sections: (j['sections'] as List?)
                ?.map((e) => MenuSection.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        promoTags: (j['promoTags'] as List?)
                ?.map((e) => PromoTag.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        featureLabels: (j['featureLabels'] as List?)?.cast<String>() ?? const [],
        notice: j['notice'] as String? ?? '',
        isOpen: j['isOpen'] as bool? ?? true,
      );
}

class MenuSection {
  final String id;     // rank/subcategory id ('' for legacy data)
  final String title;
  final String image;  // rank picture ('' -> rail shows text-only)
  final List<Product> products;

  const MenuSection({this.id = '', required this.title, this.image = '', required this.products});

  factory MenuSection.fromJson(Map<String, dynamic> j) => MenuSection(
        id: j['id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        image: j['image'] as String? ?? '',
        products: (j['products'] as List?)
                ?.map((e) => Product.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

/// One selectable SKU of a [Product] — e.g. size S / M / L / XL with its own
/// price, stock and gallery image. Drives the multi-SKU product-detail modal.
class ProductVariant {
  final String sku;
  final String label; // option display name (e.g. "M")
  final double price;
  final double oldPrice; // 0 == no discount
  final String image;
  final bool inStock;

  const ProductVariant({
    required this.sku,
    required this.label,
    required this.price,
    this.oldPrice = 0,
    this.image = '',
    this.inStock = true,
  });

  bool get hasDiscount => oldPrice > price && oldPrice > 0;

  factory ProductVariant.fromJson(Map<String, dynamic> j) => ProductVariant(
        sku: j['sku'] as String? ?? '',
        label: j['label'] as String? ?? '',
        price: (j['price'] as num?)?.toDouble() ?? 0,
        oldPrice: (j['oldPrice'] as num?)?.toDouble() ?? 0,
        image: j['image'] as String? ?? '',
        inStock: j['inStock'] as bool? ?? true,
      );
}

class Product {
  final String id; // == sku for jameia-sourced products (cart key)
  final String name;
  final String image;
  final double price; // Mart price
  final double originalPrice; // 0 == no discount (struck price)
  final String desc;
  final int soldCount;
  final int kcal;
  final String categoryId;
  final bool bestSelling;
  final List<ProductVariant> variants;

  // ── Jameia extras (tolerant of older data; default = simple Mart product) ───
  final String nameAr;
  final double vipPrice; // 0 == no distinct VIP price
  final bool available; // false → "Not available" overlay, can't add
  final int maxQty; // 0 == no per-cart cap
  final bool showDiscount; // backend "show discount %" flag (drives Promos)
  final int firstUnitsQty; // multi-buy promo (first N units) — 0 == none

  // ── Product-detail extras (optional; derived at runtime when absent) ─────────
  /// Explicit gallery image URLs for the product-detail carousel. Empty → the
  /// gallery is derived from [image] + distinct variant images ([resolvedGallery]).
  final List<String> gallery;
  /// Explicit brand name. Empty → the detail screen derives it from the taxonomy.
  final String brand;
  /// Pack size / unit label (e.g. "400 g"). Empty → parsed from the name, else omitted.
  final String weight;
  /// Storage spec value (e.g. "Frozen"). Empty → the storage spec row is omitted.
  final String storage;

  const Product({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.originalPrice,
    required this.desc,
    required this.soldCount,
    required this.kcal,
    this.categoryId = '',
    this.bestSelling = false,
    this.variants = const [],
    this.nameAr = '',
    this.vipPrice = 0,
    this.available = true,
    this.maxQty = 0,
    this.showDiscount = false,
    this.firstUnitsQty = 0,
    this.gallery = const [],
    this.brand = '',
    this.weight = '',
    this.storage = '',
  });

  bool get hasDiscount => originalPrice > price && originalPrice > 0;

  /// Images for the product-detail gallery — explicit [gallery] when provided,
  /// else the product image plus any distinct variant images (falls back to the
  /// single [image] so the pager always has at least one page).
  List<String> get resolvedGallery {
    if (gallery.isNotEmpty) return gallery;
    final out = <String>[];
    for (final url in [image, ...variants.map((v) => v.image)]) {
      if (url.isNotEmpty && !out.contains(url)) out.add(url);
    }
    return out.isEmpty ? [image] : out;
  }

  /// Returns a copy with the given fields replaced — used by the product-details
  /// dummy data source to seed a hero with a discount / gallery / storage / etc.
  Product copyWith({
    String? id,
    String? name,
    String? image,
    double? price,
    double? originalPrice,
    String? desc,
    int? soldCount,
    int? kcal,
    String? categoryId,
    bool? bestSelling,
    List<ProductVariant>? variants,
    String? nameAr,
    double? vipPrice,
    bool? available,
    int? maxQty,
    bool? showDiscount,
    int? firstUnitsQty,
    List<String>? gallery,
    String? brand,
    String? weight,
    String? storage,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      desc: desc ?? this.desc,
      soldCount: soldCount ?? this.soldCount,
      kcal: kcal ?? this.kcal,
      categoryId: categoryId ?? this.categoryId,
      bestSelling: bestSelling ?? this.bestSelling,
      variants: variants ?? this.variants,
      nameAr: nameAr ?? this.nameAr,
      vipPrice: vipPrice ?? this.vipPrice,
      available: available ?? this.available,
      maxQty: maxQty ?? this.maxQty,
      showDiscount: showDiscount ?? this.showDiscount,
      firstUnitsQty: firstUnitsQty ?? this.firstUnitsQty,
      gallery: gallery ?? this.gallery,
      brand: brand ?? this.brand,
      weight: weight ?? this.weight,
      storage: storage ?? this.storage,
    );
  }

  bool get hasVariants => variants.isNotEmpty;

  /// Locale-aware product name (Arabic when the locale is `ar` and available).
  String get displayName => localizedCatalogName(name, nameAr);

  int get discountPercent =>
      hasDiscount ? (((originalPrice - price) / originalPrice) * 100).round() : 0;

  /// SKU alias — the cart/lookup key for jameia products.
  String get sku => id;

  /// VIP price exists and actually differs from the Mart price.
  bool get hasVipPrice => vipPrice > 0 && vipPrice != price;

  /// Price to charge/display for the active store mode (Mart vs VIP).
  double priceFor(bool vip) => (vip && vipPrice > 0) ? vipPrice : price;

  /// Whether this product should surface in the Promos collection.
  bool get hasPromo =>
      showDiscount && (firstUnitsQty > 0 || hasDiscount);

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'] as String,
        name: j['name'] as String,
        image: j['image'] as String? ?? '',
        price: (j['price'] as num?)?.toDouble() ?? 0,
        originalPrice: (j['originalPrice'] as num?)?.toDouble() ?? 0,
        desc: j['desc'] as String? ?? '',
        soldCount: (j['soldCount'] as num?)?.toInt() ?? 0,
        kcal: (j['kcal'] as num?)?.toInt() ?? 0,
        categoryId: j['categoryId'] as String? ?? '',
        bestSelling: j['bestSelling'] as bool? ?? false,
        variants: (j['variants'] as List?)
                ?.map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        nameAr: j['nameAr'] as String? ?? '',
        vipPrice: (j['vipPrice'] as num?)?.toDouble() ?? 0,
        available: j['available'] as bool? ?? true,
        maxQty: (j['maxQty'] as num?)?.toInt() ?? 0,
        showDiscount: j['showDiscount'] as bool? ?? false,
        firstUnitsQty: (j['firstUnitsQty'] as num?)?.toInt() ?? 0,
        gallery: (j['gallery'] as List?)?.cast<String>() ?? const [],
        brand: j['brand'] as String? ?? '',
        weight: j['weight'] as String? ?? '',
        storage: j['storage'] as String? ?? '',
      );
}
