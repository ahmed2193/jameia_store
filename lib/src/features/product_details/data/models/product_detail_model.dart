import '../../../../core/data/models/brand_model.dart';
import '../../../../core/data/models/category_model.dart';
import '../../../../core/data/models/json_read.dart';
import '../../../../core/data/models/product_model.dart';
import '../../../../core/data/models/recipe_summary_model.dart';
import '../../../../core/error/exceptions.dart';

/// `results` of `GET /v1/products/:slug`: the product card fields plus
/// `description`, `galleryUrls`, `brand`, `category`, `variants[]`,
/// `bundleItems[]`, `related[]`, `recipes[]`.
class ProductDetailModel {
  const ProductDetailModel({
    required this.product,
    this.description = '',
    this.galleryUrls = const <String>[],
    this.brand,
    this.category,
    this.variants = const <ProductVariantModel>[],
    this.bundleItems = const <ProductBundleItemModel>[],
    this.related = const <ProductModel>[],
    this.recipes = const <RecipeSummaryModel>[],
  });

  static const String descriptionKey = 'description';
  static const String galleryUrlsKey = 'galleryUrls';
  static const String brandKey = 'brand';
  static const String categoryKey = 'category';
  static const String variantsKey = 'variants';
  static const String bundleItemsKey = 'bundleItems';
  static const String relatedKey = 'related';
  static const String recipesKey = 'recipes';
  static const String _logName = 'ProductDetailModel';

  /// Throws [ParsingException] when the product itself has no id / slug; a
  /// malformed nested row (variant, related product …) is skipped, a broken
  /// `brand` / `category` object is dropped.
  factory ProductDetailModel.fromJson(Map<String, dynamic> json) {
    return ProductDetailModel(
      product: ProductModel.fromJson(json),
      description: JsonRead.string(json[descriptionKey]) ?? '',
      galleryUrls: JsonRead.strings(json[galleryUrlsKey]),
      brand: _tryObject(json[brandKey], BrandModel.fromJson),
      category: _tryObject(json[categoryKey], CategoryModel.fromJson),
      variants: JsonRead.rows(
        json[variantsKey],
        ProductVariantModel.fromJson,
        logName: _logName,
      ),
      bundleItems: JsonRead.rows(
        json[bundleItemsKey],
        ProductBundleItemModel.fromJson,
        logName: _logName,
      ),
      related: JsonRead.rows(
        json[relatedKey],
        ProductModel.fromJson,
        logName: _logName,
      ),
      recipes: JsonRead.rows(
        json[recipesKey],
        RecipeSummaryModel.fromJson,
        logName: _logName,
      ),
    );
  }

  final ProductModel product;
  final String description;
  final List<String> galleryUrls;
  final BrandModel? brand;
  final CategoryModel? category;
  final List<ProductVariantModel> variants;
  final List<ProductBundleItemModel> bundleItems;
  final List<ProductModel> related;
  final List<RecipeSummaryModel> recipes;

  static T? _tryObject<T>(
    Object? raw,
    T Function(Map<String, dynamic> json) parse,
  ) {
    final json = JsonRead.object(raw);
    if (json == null) return null;
    try {
      return parse(json);
    } on AppException {
      return null;
    }
  }
}

/// One row of `variants[]`. Money is fils.
class ProductVariantModel {
  const ProductVariantModel({
    required this.id,
    this.name = '',
    this.price = 0,
    this.proPrice,
    this.compareAt,
    this.compareAtExpiresAt,
    this.stock = 0,
    this.enabled = true,
  });

  static const String idKey = 'id';
  static const String nameKey = 'name';
  static const String priceKey = 'price';
  static const String proPriceKey = 'proPrice';
  static const String compareAtKey = 'compareAt';
  static const String compareAtExpiresAtKey = 'compareAtExpiresAt';
  static const String stockKey = 'stock';
  static const String enabledKey = 'enabled';

  /// Throws [ParsingException] without an id: the id keys the cart line.
  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    final id = JsonRead.string(json[idKey]);
    if (id == null) throw const ParsingException('variant: id missing');
    return ProductVariantModel(
      id: id,
      name: JsonRead.string(json[nameKey]) ?? '',
      price: JsonRead.integer(json[priceKey]) ?? 0,
      proPrice: JsonRead.integer(json[proPriceKey]),
      compareAt: JsonRead.integer(json[compareAtKey]),
      compareAtExpiresAt: JsonRead.dateTime(json[compareAtExpiresAtKey]),
      stock: JsonRead.integer(json[stockKey]) ?? 0,
      enabled: JsonRead.flag(json[enabledKey], fallback: true),
    );
  }

  final String id;
  final String name;
  final int price;
  final int? proPrice;
  final int? compareAt;
  final DateTime? compareAtExpiresAt;
  final int stock;
  final bool enabled;
}

/// One row of `bundleItems[]`: `{ productId, quantity, unitPrice, product }`.
class ProductBundleItemModel {
  const ProductBundleItemModel({
    required this.product,
    this.quantity = 1,
    this.unitPrice = 0,
  });

  static const String productKey = 'product';
  static const String quantityKey = 'quantity';
  static const String unitPriceKey = 'unitPrice';

  /// Throws [ParsingException] without the nested product (nothing to show).
  factory ProductBundleItemModel.fromJson(Map<String, dynamic> json) {
    final product = JsonRead.object(json[productKey]);
    if (product == null) {
      throw const ParsingException('bundle item: product missing');
    }
    return ProductBundleItemModel(
      product: ProductModel.fromJson(product),
      quantity: JsonRead.integer(json[quantityKey]) ?? 1,
      unitPrice: JsonRead.integer(json[unitPriceKey]) ?? 0,
    );
  }

  final ProductModel product;
  final int quantity;
  final int unitPrice;
}
