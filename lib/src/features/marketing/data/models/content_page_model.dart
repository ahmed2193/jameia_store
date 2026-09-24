import '../../../../core/data/models/json_read.dart';

/// `results` of `GET /v1/pages/:slug`: `{ slug, title, body }`.
class ContentPageModel {
  const ContentPageModel({this.slug = '', this.title = '', this.body = ''});

  static const String slugKey = 'slug';
  static const String titleKey = 'title';
  static const String bodyKey = 'body';

  factory ContentPageModel.fromJson(Map<String, dynamic> json) =>
      ContentPageModel(
        slug: JsonRead.string(json[slugKey]) ?? '',
        title: JsonRead.string(json[titleKey]) ?? '',
        body: JsonRead.string(json[bodyKey]) ?? '',
      );

  final String slug;
  final String title;
  final String body;
}
