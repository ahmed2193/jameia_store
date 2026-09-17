import '../../../../core/data/jameia/jameia_models.dart';
import '../../domain/entities/featured_section_entity.dart';
import 'product_mapper.dart';

/// DTO → entity mapping for featured-section home rails. Keeps the core
/// `FeaturedSection`'s locale-live `displayName` out of the domain entity; the
/// raw name is resolved in `presentation/util/featured_section_display.dart`.
extension FeaturedSectionMapper on FeaturedSection {
  FeaturedSectionEntity toEntity() => FeaturedSectionEntity(
    id: id,
    name: name,
    nameAr: nameAr,
    sorting: sorting,
    slides: slides,
    products: products.map((p) => p.toEntity()).toList(),
  );
}

extension FeaturedSectionListMapper on List<FeaturedSection> {
  List<FeaturedSectionEntity> toEntities() => map((s) => s.toEntity()).toList();
}
