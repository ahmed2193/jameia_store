import '../../../../core/data/models/json_read.dart';

/// The `icon` of a home section, promo card or announcement item:
/// `{ source: "library", key }` (a named icon of the backend's icon set) or
/// `{ source: "custom", url }` (an uploaded image).
class HomeIconModel {
  const HomeIconModel({this.source = '', this.key = '', this.url = ''});

  static const String sourceKey = 'source';
  static const String keyKey = 'key';
  static const String urlKey = 'url';

  /// `null` when [raw] is not an object (the field is optional on the wire).
  static HomeIconModel? tryParse(Object? raw) {
    final json = JsonRead.object(raw);
    if (json == null) return null;
    return HomeIconModel(
      source: JsonRead.string(json[sourceKey]) ?? '',
      key: JsonRead.string(json[keyKey]) ?? '',
      url: JsonRead.string(json[urlKey]) ?? '',
    );
  }

  /// `library` | `custom` (wire value).
  final String source;

  /// Library icon name (`truck`, `tag`, `zap` …); `''` for a custom icon.
  final String key;

  /// Custom icon image; `''` for a library icon.
  final String url;
}
