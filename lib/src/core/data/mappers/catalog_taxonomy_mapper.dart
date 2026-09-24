import '../../domain/entities/brand_entity.dart';
import '../../domain/entities/catalog_category_entity.dart';
import '../../domain/entities/recipe_summary_entity.dart';
import '../models/brand_model.dart';
import '../models/category_model.dart';
import '../models/recipe_summary_model.dart';

/// [CategoryModel] (wire) → [CatalogCategoryEntity].
extension CatalogCategoryMapper on CategoryModel {
  CatalogCategoryEntity toEntity() => CatalogCategoryEntity(
    id: id,
    slug: slug,
    name: name,
    image: image,
    parentId: parentId,
    sortOrder: sortOrder,
    productCount: productCount,
  );
}

extension CatalogCategoryListMapper on List<CategoryModel> {
  List<CatalogCategoryEntity> toEntities() =>
      map((model) => model.toEntity()).toList(growable: false);

  /// The flat backend list as a tree.
  CatalogCategoryTree toTree() => CatalogCategoryTree(toEntities());
}

/// [BrandModel] (wire) → [BrandEntity].
extension BrandMapper on BrandModel {
  BrandEntity toEntity() => BrandEntity(
    id: id,
    slug: slug,
    name: name,
    image: image,
    description: description,
  );
}

extension BrandListMapper on List<BrandModel> {
  List<BrandEntity> toEntities() =>
      map((model) => model.toEntity()).toList(growable: false);
}

/// [RecipeSummaryModel] (wire) → [RecipeSummaryEntity].
extension RecipeSummaryMapper on RecipeSummaryModel {
  RecipeSummaryEntity toEntity() => RecipeSummaryEntity(
    id: id,
    slug: slug,
    title: title,
    imageUrl: imageUrl,
    prepMinutes: prepMinutes,
    cookMinutes: cookMinutes,
    servings: servings,
    cuisineName: cuisineName,
    dietName: dietName,
    excerpt: excerpt,
  );
}

extension RecipeSummaryListMapper on List<RecipeSummaryModel> {
  List<RecipeSummaryEntity> toEntities() =>
      map((model) => model.toEntity()).toList(growable: false);
}
