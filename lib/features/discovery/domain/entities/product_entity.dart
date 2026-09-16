import 'package:equatable/equatable.dart';

/// Framework-free product-variant entity — one selectable SKU of a
/// [ProductEntity] (size / option) with its own price, stock and image.
///
/// Owned by the discovery feature: plain Dart + equatable only, no reuse of the
/// core `ProductVariant` DTO. Carries raw fields; the data-layer mapper maps the
/// DTO in (`data/mappers/shop_mapper.dart`) and the presentation bridge
/// reconstructs it out (`presentation/util/shop_model_bridge.dart`).
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

/// Framework-free product entity — a shop menu item / hot-selling flash line.
///
/// Owned by the discovery feature (no reuse of the core `Product` DTO, no
/// `easy_localization` / `intl`). Carries the raw bilingual name so display
/// resolves live off the reconstructed core model at the presentation boundary;
/// pricing / discount derivations live here so the discovery use cases
/// (fixed-price sort) run against the entity, not the DTO.
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
  final bool available;
  final int maxQty;
  final bool showDiscount;
  final int firstUnitsQty;
  final List<String> gallery;
  final String brand;
  final String weight;
  final String storage;

  /// SKU alias — the cart/lookup key for jameia products.
  String get sku => id;

  bool get hasDiscount => originalPrice > price && originalPrice > 0;

  int get discountPercent => hasDiscount
      ? (((originalPrice - price) / originalPrice) * 100).round()
      : 0;

  bool get hasVariants => variants.isNotEmpty;

  /// VIP price exists and actually differs from the Mart price.
  bool get hasVipPrice => vipPrice > 0 && vipPrice != price;

  /// Price to charge/display for the active store mode (Mart vs VIP).
  double priceFor(bool vip) => (vip && vipPrice > 0) ? vipPrice : price;

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
