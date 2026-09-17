import '../../../../core/data/models/models.dart' show localizedCatalogName;
import '../../domain/entities/product_entity.dart';

/// Presentation-side, active-locale display for a [ProductEntity].
///
/// The entity is framework-free (raw bilingual fields only); resolving the
/// visible name is a presentation concern. Reuses the catalogue's canonical
/// locale picker so a language switch flips the text on the next rebuild —
/// matching the old `Product.displayName` getter exactly.
extension ProductDisplay on ProductEntity {
  String get displayName => localizedCatalogName(name, nameAr);
}
