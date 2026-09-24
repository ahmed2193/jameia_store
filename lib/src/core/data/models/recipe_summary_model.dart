import '../../error/exceptions.dart';
import 'json_read.dart';

/// A recipe card as the backend sends it: a row of `GET /v1/recipes`, a recipe
/// rail of `GET /v1/home` and `recipes` of a product detail.
///
/// Text arrives already resolved for `Accept-Language`.
class RecipeSummaryModel {
  const RecipeSummaryModel({
    required this.id,
    required this.slug,
    this.title = '',
    this.imageUrl = '',
    this.prepMinutes = 0,
    this.cookMinutes = 0,
    this.servings = 0,
    this.cuisineSlug = '',
    this.cuisineName = '',
    this.dietSlug = '',
    this.dietName = '',
    this.excerpt = '',
  });

  static const String mongoIdKey = '_id';
  static const String idKey = 'id';
  static const String slugKey = 'slug';
  static const String titleKey = 'title';
  static const String imageUrlKey = 'imageUrl';
  static const String prepMinutesKey = 'prepMinutes';
  static const String cookMinutesKey = 'cookMinutes';
  static const String servingsKey = 'servings';
  static const String cuisineKey = 'cuisine';
  static const String dietKey = 'diet';
  static const String nameKey = 'name';
  static const String excerptKey = 'excerpt';

  /// Throws [ParsingException] without an id or a slug.
  factory RecipeSummaryModel.fromJson(Map<String, dynamic> json) {
    final id =
        JsonRead.string(json[mongoIdKey]) ?? JsonRead.string(json[idKey]);
    if (id == null) throw const ParsingException('recipe: id missing');
    final slug = JsonRead.string(json[slugKey]);
    if (slug == null) throw const ParsingException('recipe: slug missing');
    final cuisine = JsonRead.object(json[cuisineKey]);
    final diet = JsonRead.object(json[dietKey]);
    return RecipeSummaryModel(
      id: id,
      slug: slug,
      title: JsonRead.string(json[titleKey]) ?? '',
      imageUrl: JsonRead.string(json[imageUrlKey]) ?? '',
      prepMinutes: JsonRead.integer(json[prepMinutesKey]) ?? 0,
      cookMinutes: JsonRead.integer(json[cookMinutesKey]) ?? 0,
      servings: JsonRead.integer(json[servingsKey]) ?? 0,
      cuisineSlug: JsonRead.string(cuisine?[slugKey]) ?? '',
      cuisineName: JsonRead.string(cuisine?[nameKey]) ?? '',
      dietSlug: JsonRead.string(diet?[slugKey]) ?? '',
      dietName: JsonRead.string(diet?[nameKey]) ?? '',
      excerpt: JsonRead.string(json[excerptKey]) ?? '',
    );
  }

  final String id;
  final String slug;
  final String title;
  final String imageUrl;
  final int prepMinutes;
  final int cookMinutes;
  final int servings;
  final String cuisineSlug;
  final String cuisineName;
  final String dietSlug;
  final String dietName;

  /// One-line teaser (recipe list + detail only; rails omit it).
  final String excerpt;
}
