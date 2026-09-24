import '../../error/exceptions.dart';
import 'json_read.dart';

/// A brand as the backend sends it: a row of `GET /v1/brands`, the object of
/// `GET /v1/brands/:slug`, a brand rail of `GET /v1/home` and `brand` of a
/// product detail (the last two carry no [description]).
///
/// [name] / [description] arrive already resolved for `Accept-Language`.
class BrandModel {
  const BrandModel({
    required this.id,
    required this.slug,
    this.name = '',
    this.image = '',
    this.description = '',
  });

  static const String mongoIdKey = '_id';
  static const String idKey = 'id';
  static const String slugKey = 'slug';
  static const String nameKey = 'name';
  static const String imageKey = 'image';
  static const String descriptionKey = 'description';

  /// Throws [ParsingException] without an id or a slug.
  factory BrandModel.fromJson(Map<String, dynamic> json) {
    final id =
        JsonRead.string(json[mongoIdKey]) ?? JsonRead.string(json[idKey]);
    if (id == null) throw const ParsingException('brand: id missing');
    final slug = JsonRead.string(json[slugKey]);
    if (slug == null) throw const ParsingException('brand: slug missing');
    return BrandModel(
      id: id,
      slug: slug,
      name: JsonRead.string(json[nameKey]) ?? '',
      image: JsonRead.string(json[imageKey]) ?? '',
      description: JsonRead.string(json[descriptionKey]) ?? '',
    );
  }

  final String id;
  final String slug;
  final String name;

  /// May be `''`: the UI falls back to the brand's initial.
  final String image;
  final String description;
}
