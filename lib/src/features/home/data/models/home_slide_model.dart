import '../../../../core/data/models/json_read.dart';
import '../../../../core/error/exceptions.dart';

/// One hero slide of `GET /v1/home` → `results.slides[]`.
/// Text arrives already resolved for `Accept-Language`.
class HomeSlideModel {
  const HomeSlideModel({
    required this.id,
    required this.imageUrl,
    this.sortOrder = 0,
    this.title = '',
    this.description = '',
    this.status = activeStatus,
  });

  static const String mongoIdKey = '_id';
  static const String idKey = 'id';
  static const String sortOrderKey = 'sortOrder';
  static const String titleKey = 'title';
  static const String descriptionKey = 'description';
  static const String imageUrlKey = 'imageUrl';
  static const String statusKey = 'status';
  static const String activeStatus = 'active';

  /// Throws [ParsingException] without an id or an image: a slide is its image.
  factory HomeSlideModel.fromJson(Map<String, dynamic> json) {
    final id =
        JsonRead.string(json[mongoIdKey]) ?? JsonRead.string(json[idKey]);
    if (id == null) throw const ParsingException('home slide: id missing');
    final imageUrl = JsonRead.string(json[imageUrlKey]);
    if (imageUrl == null) {
      throw const ParsingException('home slide: imageUrl missing');
    }
    return HomeSlideModel(
      id: id,
      imageUrl: imageUrl,
      sortOrder: JsonRead.integer(json[sortOrderKey]) ?? 0,
      title: JsonRead.string(json[titleKey]) ?? '',
      description: JsonRead.string(json[descriptionKey]) ?? '',
      status: JsonRead.string(json[statusKey]) ?? activeStatus,
    );
  }

  final String id;
  final String imageUrl;
  final int sortOrder;
  final String title;
  final String description;

  /// `active` | `scheduled` | `archived` | `inactive` (wire value). The route
  /// already filters by schedule; the mapper still drops a non-active slide.
  final String status;
}
