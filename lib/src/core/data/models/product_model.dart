import '../../error/exceptions.dart';
import 'json_read.dart';

/// A catalogue product card as the backend sends it: a row of
/// `GET /v1/products`, a product rail of `GET /v1/home`, and the `related` /
/// `bundleItems[].product` rows of `GET /v1/products/:slug`. Shared by home,
/// shop, product_details and search, so it lives in `core/data/models`.
///
/// [name] arrives already resolved for `Accept-Language`. Money is fils.
///
/// Reference: https://api.jm3eia.store/docs (Catalog → `GET /v1/products`)
class ProductModel {
  const ProductModel({
    required this.id,
    required this.slug,
    this.name = '',
    this.type = standardType,
    this.price = 0,
    this.proPrice,
    this.compareAt,
    this.image = '',
    this.stock = 0,
    this.tags = const <String>[],
    this.unitOfSale = pieceUnit,
    this.ratingAverage = 0,
    this.ratingCount = 0,
  });

  static const String mongoIdKey = '_id';
  static const String idKey = 'id';
  static const String slugKey = 'slug';
  static const String nameKey = 'name';
  static const String typeKey = 'type';
  static const String priceKey = 'price';
  static const String proPriceKey = 'proPrice';
  static const String compareAtKey = 'compareAt';
  static const String imageKey = 'image';
  static const String stockKey = 'stock';
  static const String tagsKey = 'tags';
  static const String unitOfSaleKey = 'unitOfSale';
  static const String ratingAverageKey = 'ratingAverage';
  static const String ratingCountKey = 'ratingCount';
  static const String standardType = 'standard';
  static const String pieceUnit = 'piece';

  /// Throws [ParsingException] without an id or a slug: the id keys the cart
  /// line and the slug is the only way to open the product.
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final id =
        JsonRead.string(json[mongoIdKey]) ?? JsonRead.string(json[idKey]);
    if (id == null) throw const ParsingException('product: id missing');
    final slug = JsonRead.string(json[slugKey]);
    if (slug == null) throw const ParsingException('product: slug missing');
    return ProductModel(
      id: id,
      slug: slug,
      name: JsonRead.string(json[nameKey]) ?? '',
      type: JsonRead.string(json[typeKey]) ?? standardType,
      price: JsonRead.integer(json[priceKey]) ?? 0,
      proPrice: JsonRead.integer(json[proPriceKey]),
      compareAt: JsonRead.integer(json[compareAtKey]),
      image: JsonRead.string(json[imageKey]) ?? '',
      stock: JsonRead.integer(json[stockKey]) ?? 0,
      tags: JsonRead.strings(json[tagsKey]),
      unitOfSale: JsonRead.string(json[unitOfSaleKey]) ?? pieceUnit,
      ratingAverage: JsonRead.decimal(json[ratingAverageKey]) ?? 0,
      ratingCount: JsonRead.integer(json[ratingCountKey]) ?? 0,
    );
  }

  /// The wire shape back, for the on-device cart mirror.
  Map<String, dynamic> toJson() => <String, dynamic>{
    mongoIdKey: id,
    slugKey: slug,
    nameKey: name,
    typeKey: type,
    priceKey: price,
    if (proPrice != null) proPriceKey: proPrice,
    if (compareAt != null) compareAtKey: compareAt,
    imageKey: image,
    stockKey: stock,
    tagsKey: tags,
    unitOfSaleKey: unitOfSale,
    ratingAverageKey: ratingAverage,
    ratingCountKey: ratingCount,
  };

  final String id;
  final String slug;
  final String name;

  /// `standard` | `variant` | `bundle` (wire value; the mapper picks the enum).
  final String type;

  /// Fils. `0` on a `variant` product: its prices live on the variants.
  final int price;

  /// Pro-member price in fils, or `null`.
  final int? proPrice;

  /// Struck "was" price in fils, or `null`.
  final int? compareAt;
  final String image;
  final int stock;

  /// Tag slugs. The backend also leaks raw tag ids here; the mapper drops them.
  final List<String> tags;

  /// `piece` | `kg` | `l` | `pack` (wire value).
  final String unitOfSale;
  final double ratingAverage;
  final int ratingCount;
}
