import '../../domain/entities/menu_section_entity.dart';
import '../models/shop.dart';
import 'product_mapper.dart';

/// `MenuSection` DTO → [MenuSectionEntity].
extension MenuSectionMapper on MenuSection {
  MenuSectionEntity toEntity() => MenuSectionEntity(
    id: id,
    title: title,
    image: image,
    products: products.toEntities(),
  );
}

extension MenuSectionListMapper on List<MenuSection> {
  List<MenuSectionEntity> toEntities() =>
      map((s) => s.toEntity()).toList(growable: false);
}
