import '../../domain/entities/jameia_sub_category_entity.dart';
import '../jameia/jameia_models.dart';
import 'jameia_rank_mapper.dart';
import 'product_mapper.dart';

/// `JameiaSubCategory` DTO → [JameiaSubCategoryEntity].
extension JameiaSubCategoryMapper on JameiaSubCategory {
  JameiaSubCategoryEntity toEntity() => JameiaSubCategoryEntity(
    id: id,
    name: name,
    nameAr: nameAr,
    image: image,
    banner: banner,
    ranks: ranks.toEntities(),
    directProducts: directProducts.toEntities(),
  );
}

extension JameiaSubCategoryListMapper on List<JameiaSubCategory> {
  List<JameiaSubCategoryEntity> toEntities() =>
      map((s) => s.toEntity()).toList(growable: false);
}
