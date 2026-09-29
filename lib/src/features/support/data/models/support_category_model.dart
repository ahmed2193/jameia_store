import '../../../../core/data/models/json_read.dart';
import '../../../../core/error/exceptions.dart';

/// One topic row of a category (`children[]`).
class SupportTopicModel {
  const SupportTopicModel({
    required this.key,
    this.requireOrder = false,
    this.requireProducts = false,
  });

  static const String keyKey = 'key';
  static const String requireOrderKey = 'requireOrder';
  static const String requireProductsKey = 'requireProducts';

  /// Throws [ParsingException] without a `key` (the row is skipped).
  factory SupportTopicModel.fromJson(Map<String, dynamic> json) {
    final key = JsonRead.string(json[keyKey]);
    if (key == null) throw const ParsingException('support topic: key missing');
    return SupportTopicModel(
      key: key,
      requireOrder: JsonRead.flag(json[requireOrderKey]),
      requireProducts: JsonRead.flag(json[requireProductsKey]),
    );
  }

  final String key;
  final bool requireOrder;
  final bool requireProducts;
}

/// One row of `GET /v1/support/categories` → `data[]`.
class SupportCategoryModel {
  const SupportCategoryModel({
    required this.key,
    this.requireOrder = false,
    this.requireProducts = false,
    this.children = const <SupportTopicModel>[],
  });

  static const String keyKey = 'key';
  static const String requireOrderKey = 'requireOrder';
  static const String requireProductsKey = 'requireProducts';
  static const String childrenKey = 'children';
  static const String _logName = 'SupportCategoryModel';

  /// Throws [ParsingException] without a `key` (the row is skipped); a
  /// malformed topic row is skipped, never the category.
  factory SupportCategoryModel.fromJson(Map<String, dynamic> json) {
    final key = JsonRead.string(json[keyKey]);
    if (key == null) {
      throw const ParsingException('support category: key missing');
    }
    return SupportCategoryModel(
      key: key,
      requireOrder: JsonRead.flag(json[requireOrderKey]),
      requireProducts: JsonRead.flag(json[requireProductsKey]),
      children: JsonRead.rows(
        json[childrenKey],
        SupportTopicModel.fromJson,
        logName: _logName,
      ),
    );
  }

  final String key;
  final bool requireOrder;
  final bool requireProducts;
  final List<SupportTopicModel> children;
}

/// `GET /v1/support/categories` → `{ data: [Category] }`.
class SupportCategoriesModel {
  const SupportCategoriesModel(this.categories);

  static const String dataKey = 'data';
  static const String _logName = 'SupportCategoriesModel';

  factory SupportCategoriesModel.fromJson(Map<String, dynamic> json) =>
      SupportCategoriesModel(
        JsonRead.rows(
          json[dataKey],
          SupportCategoryModel.fromJson,
          logName: _logName,
        ),
      );

  final List<SupportCategoryModel> categories;
}
