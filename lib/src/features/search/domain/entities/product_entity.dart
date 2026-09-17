import 'package:equatable/equatable.dart';

import 'product_variant_entity.dart';

/// Framework-free product entity owned by the search feature (no reuse of the
/// core `Product` DTO, no `easy_localization` / `intl`). Carries the raw bilingual
/// name so the presentation layer resolves the active-locale display **live**
/// (see `presentation/util/product_display.dart`) — a language switch rebuilds
/// the tree, so display text stays correct without reloading the cubit.
///
/// All raw scalar fields (plus [variants]) are carried so a search-rail product
/// can be reconstructed losslessly into the core DTO at the single cross-feature
/// product-detail push boundary (see `presentation/util/product_boundary.dart`).
class ProductEntity extends Equatable {
  const ProductEntity({
    required this.id,
    required this.name,
    this.nameAr = '',
    required this.image,
    required this.price,
    required this.originalPrice,
    this.desc = '',
    this.soldCount = 0,
    this.kcal = 0,
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

  final String id;

  /// English / default name + its Arabic counterpart (resolved live in
  /// presentation via `ProductDisplay.displayName`).
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
  final bool available;
  final int maxQty;
  final bool showDiscount;
  final int firstUnitsQty;
  final List<String> gallery;
  final String brand;
  final String weight;
  final String storage;

  bool get hasDiscount => originalPrice > price && originalPrice > 0;

  bool get hasVariants => variants.isNotEmpty;

  /// SKU alias — the cart/lookup key.
  String get sku => id;

  int get discountPercent => hasDiscount
      ? (((originalPrice - price) / originalPrice) * 100).round()
      : 0;

  /// VIP price exists and actually differs from the Mart price.
  bool get hasVipPrice => vipPrice > 0 && vipPrice != price;

  /// Price to charge/display for the active store mode (Mart vs VIP).
  double priceFor(bool vip) => (vip && vipPrice > 0) ? vipPrice : price;

  /// Whether this product should surface in the Promos collection.
  bool get hasPromo => showDiscount && (firstUnitsQty > 0 || hasDiscount);

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
