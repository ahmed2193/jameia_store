import '../../../../core/data/models/models.dart' show localizedCatalogName;
import '../../domain/entities/product_detail.dart';

/// Presentation-side, active-locale display for the product-detail view models.
///
/// [DealVM] / [RecipeVM] are framework-free (raw bilingual fields only);
/// resolving the visible string is a presentation concern, so it lives here.
/// Reuses the catalogue's canonical locale picker (`localizedCatalogName`, which
/// reads the live `Intl.defaultLocale`) so a language switch flips the text on
/// the next rebuild — matching the old inline `displayTitle` getters exactly.
extension DealDisplay on DealVM {
  String get displayTitle => localizedCatalogName(title, titleAr);
  String get displaySubtitle => localizedCatalogName(subtitle, subtitleAr);
}

extension RecipeDisplay on RecipeVM {
  String get displayTitle => localizedCatalogName(title, titleAr);
}
