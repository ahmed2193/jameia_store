import 'package:equatable/equatable.dart';

// TODO(P2.9-boundary): the core [Product] catalogue DTO is carried here rather
// than a framework-free `ProductEntity` because every product in this feature
// is consumed by ANOTHER feature's API — `cart.add` / `quickAddToCart` /
// `showProductSku` all require the core `Product`/`ProductVariant`, and
// home/shop/search push `ProductDetailPage(product: <core Product>)`. Minting
// an entity would force a DTO round-trip at each of those cross-feature call
// sites, which the boundary rule forbids. The framework coupling that CAN be
// removed (the locale-live display getters) has been moved to
// `presentation/util/product_detail_display.dart`.
import '../../../../core/data/models/models.dart';

/// The fully-resolved product-detail aggregate (KeeMart PDP). Built once by the
/// data source and carried through the use case into the cubit; the ordered
/// sections are rendered by the screen. Reuses the core [Product] catalogue type
/// for the hero + similar/explore grids rather than re-declaring it.
class ProductDetail extends Equatable {
  const ProductDetail({
    required this.product,
    required this.gallery,
    required this.kcal,
    required this.storage,
    required this.weight,
    required this.prepMinutes,
    required this.brand,
    required this.deals,
    required this.similar,
    required this.recipes,
    required this.exploreMore,
  });

  /// Hero product (seeded with a discount / gallery / storage for the reference
  /// look). Drives the title, price, sticky bar and add-to-cart.
  final Product product;

  /// Gallery image URLs (≥ 1). When > 1 the pager shows an "Image i/n" counter.
  final List<String> gallery;

  /// Calories for the nutrition panel (0 → the Nutrition segment is hidden).
  final int kcal;

  /// Storage spec value shown in "Product details" (e.g. "Frozen"). '' → hidden.
  final String storage;

  /// Pack size shown in "Product details" (e.g. "400 g"). '' → hidden.
  final String weight;

  /// Preparation minutes for the delivery ETA row.
  final int prepMinutes;

  /// Brand-floor link ("Explore all products").
  final BrandInfo brand;

  /// "Super deals" coupon cards.
  final List<DealVM> deals;

  /// "Similar Products" grid.
  final List<Product> similar;

  /// "Recommended Recipes" rail.
  final List<RecipeVM> recipes;

  /// "Explore More" grid.
  final List<Product> exploreMore;

  bool get hasNutrition => kcal > 0;

  @override
  List<Object?> get props => [
    product.id,
    gallery,
    kcal,
    storage,
    weight,
    prepMinutes,
    brand,
    deals,
    similar,
    recipes,
    exploreMore,
  ];
}

/// Brand-row link data (logo tile + name + "Explore all products" → category).
class BrandInfo extends Equatable {
  const BrandInfo({
    required this.name,
    required this.logo,
    required this.categoryId,
  });

  final String name;
  final String logo;
  final String categoryId;

  @override
  List<Object?> get props => [name, logo, categoryId];
}

/// A "Super deals" coupon. Raw EN/AR copy (locale-resolved live via the
/// `DealDisplay` extension in `presentation/util/product_detail_display.dart`) +
/// spend threshold + a live-countdown deadline. [percent] drives the bold
/// "{n}% off" lead when the coupon has no explicit title.
class DealVM extends Equatable {
  const DealVM({
    required this.percent,
    required this.title,
    required this.titleAr,
    required this.subtitle,
    required this.subtitleAr,
    required this.minSpend,
    required this.deadline,
  });

  final int percent;
  final String title;
  final String titleAr;
  final String subtitle;
  final String subtitleAr;
  final double minSpend;
  final DateTime deadline;

  @override
  List<Object?> get props => [
    percent,
    title,
    titleAr,
    subtitle,
    subtitleAr,
    minSpend,
    deadline,
  ];
}

/// A "Recommended Recipes" card (image + calories + title + cook time).
class RecipeVM extends Equatable {
  const RecipeVM({
    required this.image,
    required this.title,
    required this.titleAr,
    required this.kcal,
    required this.minutes,
  });

  final String image;
  final String title;
  final String titleAr;
  final int kcal;
  final int minutes;

  @override
  List<Object?> get props => [image, title, titleAr, kcal, minutes];
}
