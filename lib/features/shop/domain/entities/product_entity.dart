import 'package:equatable/equatable.dart';

import 'product_variant_entity.dart';

/// Framework-free product entity.
///
/// Owned by the shop feature (no reuse of the core `Product` DTO, no
/// `easy_localization` / `intl`). Carries the raw bilingual `name` / `nameAr`
/// so presentation resolves the active-locale display **live** (see
/// `presentation/util/shop_display.dart`). All pricing / derivation the
/// presentation needs is expressed as plain methods here — notably
/// [priceFor], which was `Product.priceFor(bool)`.
class ProductEntity extends Equatable {
  const ProductEntity({
    required this.id,
    required this.name,
    this.nameAr = '',
    required this.image,
    required this.price,
    required this.originalPrice,
    required this.desc,
    required this.soldCount,
    required this.kcal,
    this.categoryId = '',
    this.bestSelling = false,
    this.variants = const [],
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

  /// == sku for jameia-sourced products (cart key).
  final String id;

  /// English / default name + its Arabic counterpart (resolved live in
  /// presentation, never frozen here).
  final String name;
  final String nameAr;

  final String image;

  /// Mart price.
  final double price;

  /// 0 == no discount (struck price).
  final double originalPrice;
  final String desc;
  final int soldCount;
  final int kcal;
  final String categoryId;
  final bool bestSelling;
  final List<ProductVariantEntity> variants;

  /// 0 == no distinct VIP price.
  final double vipPrice;

  /// false → "Not available" overlay, can't add.
  final bool available;

  /// 0 == no per-cart cap.
  final int maxQty;

  /// Backend "show discount %" flag (drives Promos).
  final bool showDiscount;

  /// Multi-buy promo (first N units) — 0 == none.
  final int firstUnitsQty;

  final List<String> gallery;
  final String brand;
  final String weight;
  final String storage;

  bool get hasDiscount => originalPrice > price && originalPrice > 0;

  bool get hasVariants => variants.isNotEmpty;

  int get discountPercent =>
      hasDiscount ? (((originalPrice - price) / originalPrice) * 100).round() : 0;

  /// SKU alias — the cart/lookup key for jameia products.
  String get sku => id;

  /// VIP price exists and actually differs from the Mart price.
  bool get hasVipPrice => vipPrice > 0 && vipPrice != price;

  /// Price to charge/display for the active store mode (Mart vs VIP). Ported
  /// verbatim from `Product.priceFor` so the pricing math stays identical.
  double priceFor(bool vip) => (vip && vipPrice > 0) ? vipPrice : price;

  /// Whether this product should surface in the Promos collection.
  bool get hasPromo => showDiscount && (firstUnitsQty > 0 || hasDiscount);

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

  @override
  List<Object?> get props => [
        id,
        name,
        nameAr,
        image,
        price,
        originalPrice,
        desc,
        soldCount,
        kcal,
        categoryId,
        bestSelling,
        variants,
        vipPrice,
        available,
        maxQty,
        showDiscount,
        firstUnitsQty,
        gallery,
        brand,
        weight,
        storage,
      ];
}
