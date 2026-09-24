import 'package:equatable/equatable.dart';

/// How a backend product is sold: one price, a choice of variants (the card
/// carries no price of its own), or a fixed bundle of other products.
enum CatalogProductType { standard, variant, bundle, other }

/// The unit a price refers to (`per piece`, `per kg` …).
enum UnitOfSale { piece, kg, litre, pack, other }

/// A product of the jm3eia backend catalogue as every list shows it: home
/// rails, category / brand / collection listings, search results, the related
/// and bundle rows of a product page.
///
/// API contract: [id] is the Mongo id (cart / wishlist key), [slug] opens the
/// product (`GET /v1/products/:slug`), money is `int` fils, [name] arrives
/// already resolved for the request language — a language switch reloads the
/// screen instead of picking another field.
///
/// The offline `ProductEntity` family stays beside it until cart, checkout and
/// orders move to the API (`CLAUDE.md` §12).
class CatalogProductEntity extends Equatable {
  const CatalogProductEntity({
    required this.id,
    required this.slug,
    required this.name,
    this.type = CatalogProductType.standard,
    this.priceFils = 0,
    this.proPriceFils,
    this.compareAtFils,
    this.image = '',
    this.stock = 0,
    this.tags = const <String>[],
    this.unitOfSale = UnitOfSale.piece,
    this.ratingAverage = 0,
    this.ratingCount = 0,
  });

  static const int filsPerDinar = 1000;
  static const int _percent = 100;

  final String id;
  final String slug;
  final String name;
  final CatalogProductType type;

  /// `0` on a [CatalogProductType.variant] product: its prices live on the
  /// variants of the product page (see [hasListPrice]).
  final int priceFils;

  /// Pro-member price, when the product has one.
  final int? proPriceFils;

  /// Struck "was" price, when the product is on sale.
  final int? compareAtFils;
  final String image;
  final int stock;

  /// Tag slugs (`fresh`, `best-seller` …).
  final List<String> tags;
  final UnitOfSale unitOfSale;
  final double ratingAverage;
  final int ratingCount;

  bool get isVariant => type == CatalogProductType.variant;
  bool get isBundle => type == CatalogProductType.bundle;
  bool get inStock => stock > 0;
  bool get hasRating => ratingCount > 0;

  /// Whether the card may print a price. A variant product has none: show the
  /// "multiple sizes" hint and let the product page price it.
  bool get hasListPrice => priceFils > 0;

  /// Whether one tap can add it to the cart (a variant needs a choice first).
  bool get canQuickAdd => inStock && !isVariant && hasListPrice;

  bool get hasProPrice {
    final pro = proPriceFils;
    return pro != null && pro > 0 && pro < priceFils;
  }

  /// The price this customer pays: the Pro price for a Pro member when the
  /// product has one, else the regular price.
  int priceFilsFor({required bool pro}) =>
      pro && hasProPrice ? proPriceFils! : priceFils;

  bool get hasDiscount {
    final compareAt = compareAtFils;
    return hasListPrice && compareAt != null && compareAt > priceFils;
  }

  /// Whole percent off [compareAtFils]; `0` without a discount.
  int get discountPercent => hasDiscount
      ? (((compareAtFils! - priceFils) * _percent) / compareAtFils!).round()
      : 0;

  double get priceKd => priceFils / filsPerDinar;
  double priceKdFor({required bool pro}) =>
      priceFilsFor(pro: pro) / filsPerDinar;

  /// `0` without a discount (what `PriceText.originalPrice` expects).
  double get compareAtKd => hasDiscount ? compareAtFils! / filsPerDinar : 0;

  bool hasTag(String tag) => tags.contains(tag);

  @override
  List<Object?> get props => [
    id,
    slug,
    name,
    type,
    priceFils,
    proPriceFils,
    compareAtFils,
    image,
    stock,
    tags,
    unitOfSale,
    ratingAverage,
    ratingCount,
  ];
}
