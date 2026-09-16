import '../../../../core/data/models/models.dart' show localizedCatalogName;
import '../../domain/entities/featured_section_entity.dart';

/// Presentation-side, active-locale display for a [FeaturedSectionEntity].
extension FeaturedSectionDisplay on FeaturedSectionEntity {
  String get displayName => localizedCatalogName(name, nameAr);
}
