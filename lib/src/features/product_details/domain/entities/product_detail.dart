import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/brand_entity.dart';
import '../../../../core/domain/entities/catalog_category_entity.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/domain/entities/catalog_variant_entity.dart';
import '../../../../core/domain/entities/recipe_summary_entity.dart';

/// One product of a bundle: what it is, how many, and what it costs inside the
/// bundle.
class ProductBundleItem extends Equatable {
  const ProductBundleItem({
    required this.product,
    this.quantity = 1,
    this.unitPriceFils = 0,
  });

  final CatalogProductEntity product;
  final int quantity;
  final int unitPriceFils;

  double get unitPriceKd => unitPriceFils / CatalogProductEntity.filsPerDinar;

  @override
  List<Object?> get props => [product, quantity, unitPriceFils];
}

/// The product page as `GET /v1/products/:slug` sends it. Owns the buying
/// rules of the page, so the cubit and the widgets only ask.
class ProductDetail extends Equatable {
  const ProductDetail({
    required this.product,
    this.description = '',
    this.galleryUrls = const <String>[],
    this.brand,
    this.category,
    this.variants = const <CatalogVariantEntity>[],
    this.bundleItems = const <ProductBundleItem>[],
    this.related = const <CatalogProductEntity>[],
    this.recipes = const <RecipeSummaryEntity>[],
  });

  final CatalogProductEntity product;
  final String description;
  final List<String> galleryUrls;
  final BrandEntity? brand;
  final CatalogCategoryEntity? category;

  /// Every option of a variant product, available or not (an unavailable one
  /// is shown but cannot be chosen).
  final List<CatalogVariantEntity> variants;
  final List<ProductBundleItem> bundleItems;
  final List<CatalogProductEntity> related;
  final List<RecipeSummaryEntity> recipes;

  /// The pager always has at least one page: the gallery, else the card image.
  List<String> get gallery => galleryUrls.isNotEmpty
      ? galleryUrls
      : <String>[if (product.image.isNotEmpty) product.image];

  /// A variant product is bought through one of its [variants].
  bool get needsVariant => product.isVariant && variants.isNotEmpty;

  /// Pre-selected option: the first one that can be bought.
  CatalogVariantEntity? get defaultVariant {
    for (final variant in variants) {
      if (variant.isAvailable) return variant;
    }
    return null;
  }

  CatalogVariantEntity? variantById(String? id) {
    if (id == null) return null;
    for (final variant in variants) {
      if (variant.id == id) return variant;
    }
    return null;
  }

  /// Whether [variant] (or the product itself) can go into the cart.
  bool canAdd(CatalogVariantEntity? variant) => needsVariant
      ? variant != null && variant.isAvailable
      : product.inStock && product.hasListPrice;

  /// How many units can still be bought.
  int stockOf(CatalogVariantEntity? variant) =>
      needsVariant ? variant?.stock ?? 0 : product.stock;

  int unitPriceFils({
    required CatalogVariantEntity? variant,
    required bool pro,
  }) => needsVariant
      ? variant?.priceFilsFor(pro: pro) ?? 0
      : product.priceFilsFor(pro: pro);

  /// What [quantity] units of the selection cost, in KD (the buy bar's total).
  double lineTotalKd({
    required CatalogVariantEntity? variant,
    required bool pro,
    required int quantity,
  }) =>
      unitPriceFils(variant: variant, pro: pro) *
      quantity /
      CatalogProductEntity.filsPerDinar;

  /// The struck price valid at [now], or `null`.
  int? compareAtFils({
    required CatalogVariantEntity? variant,
    required DateTime now,
  }) => needsVariant
      ? variant?.compareAtFilsAt(now)
      : (product.hasDiscount ? product.compareAtFils : null);

  /// Whole percent off the struck price valid at [now]; `0` without one.
  int discountPercent({
    required CatalogVariantEntity? variant,
    required DateTime now,
  }) => needsVariant
      ? variant?.discountPercentAt(now) ?? 0
      : product.discountPercent;

  /// The regular price when [pro] pays less than it (the "instead of" hint).
  int? regularPriceFilsWhenPro({
    required CatalogVariantEntity? variant,
    required bool pro,
  }) {
    if (!pro) return null;
    final hasProPrice = needsVariant
        ? variant?.hasProPrice ?? false
        : product.hasProPrice;
    if (!hasProPrice) return null;
    return needsVariant ? variant!.priceFils : product.priceFils;
  }

  /// The Pro price a non-member could get, or `null`.
  int? proPriceFilsHint({required CatalogVariantEntity? variant}) {
    if (needsVariant) {
      return (variant?.hasProPrice ?? false) ? variant!.proPriceFils : null;
    }
    return product.hasProPrice ? product.proPriceFils : null;
  }

  @override
  List<Object?> get props => [
    product,
    description,
    galleryUrls,
    brand,
    category,
    variants,
    bundleItems,
    related,
    recipes,
  ];
}
