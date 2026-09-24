import '../../error/exceptions.dart';
import 'json_read.dart';

/// A catalogue category as the backend sends it: a row of
/// `GET /v1/categories` (the whole tree, flat, linked by [parentId]), the
/// `category` / `breadcrumbs` / `children` of `GET /v1/categories/:slug`, a
/// category rail of `GET /v1/home` and `category` of a product detail.
///
/// [name] arrives already resolved for `Accept-Language`.
class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.slug,
    this.name = '',
    this.image = '',
    this.parentId,
    this.sortOrder = 0,
    this.productCount = 0,
  });

  static const String mongoIdKey = '_id';
  static const String idKey = 'id';
  static const String slugKey = 'slug';
  static const String nameKey = 'name';
  static const String imageKey = 'image';
  static const String parentIdKey = 'parentId';
  static const String sortOrderKey = 'sortOrder';
  static const String productCountKey = 'productCount';

  /// Throws [ParsingException] without an id or a slug (the slug is what the
  /// product list filters by).
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final id =
        JsonRead.string(json[mongoIdKey]) ?? JsonRead.string(json[idKey]);
    if (id == null) throw const ParsingException('category: id missing');
    final slug = JsonRead.string(json[slugKey]);
    if (slug == null) throw const ParsingException('category: slug missing');
    return CategoryModel(
      id: id,
      slug: slug,
      name: JsonRead.string(json[nameKey]) ?? '',
      image: JsonRead.string(json[imageKey]) ?? '',
      parentId: JsonRead.string(json[parentIdKey]),
      sortOrder: JsonRead.integer(json[sortOrderKey]) ?? 0,
      productCount: JsonRead.integer(json[productCountKey]) ?? 0,
    );
  }

  final String id;
  final String slug;
  final String name;
  final String image;

  /// `null` for a top-level category.
  final String? parentId;
  final int sortOrder;
  final int productCount;
}
