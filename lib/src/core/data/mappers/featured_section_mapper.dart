import '../../domain/entities/featured_section_entity.dart';
import '../jameia/jameia_models.dart';
import 'product_mapper.dart';

/// `FeaturedSection` DTO → [FeaturedSectionEntity].
extension FeaturedSectionMapper on FeaturedSection {
  FeaturedSectionEntity toEntity() => FeaturedSectionEntity(
    id: id,
    name: name,
    nameAr: nameAr,
    sorting: sorting,
    slides: slides,
    products: products.toEntities(),
  );
}

extension FeaturedSectionListMapper on List<FeaturedSection> {
  List<FeaturedSectionEntity> toEntities() =>
      map((s) => s.toEntity()).toList(growable: false);
}
