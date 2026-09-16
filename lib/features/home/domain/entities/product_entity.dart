import 'package:equatable/equatable.dart';

/// Framework-free selectable SKU of a [ProductEntity] (size S/M/L, etc.).
///
/// Owned by the home feature; plain Dart + equatable, no core-model import. The
/// data-layer mapper builds this from the core `ProductVariant` DTO.
class ProductVariantEntity extends Equatable {
  const ProductVariantEntity({
    required this.sku,
    required this.label,
    required this.price,
    this.oldPrice = 0,
    this.image = '',
    this.inStock = true,
  });

  final String sku;
  final String label;
  final double price;
  final double oldPrice; // 0 == no discount
  final String image;
  final bool inStock;

  bool get hasDiscount => oldPrice > price && oldPrice > 0;

  @override
  List<Object?> get props => [sku, label, price, oldPrice, image, inStock];
}

/// Framework-free product entity.
///
/// Owned by the home feature (no reuse of the core `Product` DTO, no
/// `easy_localization` / `intl`). Carries the raw bilingual name so the
/// presentation layer resolves the active-locale display **live** (see
/// `presentation/util/product_display.dart`). Pricing/derivation the feed cards
/// need lives on the entity (`priceFor`, `discountPercent`, …). Every raw field
/// of the source DTO is carried so the data-layer reverse mapper can rebuild the
/// core `Product` at the cart / product-detail boundary.
class ProductEntity extends Equatable {
  const ProductEntity({
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

  final String id; // == sku for jameia-sourced products (cart key)
  final String name;
  final String nameAr;
  final String image;
  final double price; // Mart price
  final double originalPrice; // 0 == no discount (struck price)
  final String desc;
  final int soldCount;
  final int kcal;
  final String categoryId;
  final bool bestSelling;
  final List<ProductVariantEntity> variants;
  final double vipPrice; // 0 == no distinct VIP price
  final bool available; // false → "Not available" overlay, can't add
  final int maxQty; // 0 == no per-cart cap
  final bool showDiscount;
  final int firstUnitsQty;
  final List<String> gallery;
  final String brand;
  final String weight;
  final String storage;

  bool get hasDiscount => originalPrice > price && originalPrice > 0;

  /// SKU alias — the cart/lookup key for jameia products.
  String get sku => id;

  bool get hasVariants => variants.isNotEmpty;

  bool get hasVipPrice => vipPrice > 0 && vipPrice != price;

  /// Price to charge/display for the active store mode (Mart vs VIP).
  double priceFor(bool vip) => (vip && vipPrice > 0) ? vipPrice : price;

  int get discountPercent =>
      hasDiscount ? (((originalPrice - price) / originalPrice) * 100).round() : 0;

  /// Whether this product should surface in the Promos collection.
  bool get hasPromo => showDiscount && (firstUnitsQty > 0 || hasDiscount);

  /// Images for the product-detail gallery — explicit [gallery] when provided,
  /// else the product image plus any distinct variant images.
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
