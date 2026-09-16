import '../../../../core/data/models/models.dart' show localizedCatalogName;
import '../../domain/entities/shop_entity.dart';

/// Presentation-side, active-locale display for a [ShopEntity].
///
/// The entity is framework-free (raw bilingual name only); resolving the
/// visible string is a presentation concern, so it lives here. Reuses the
/// catalogue's canonical locale picker (`localizedCatalogName`, which reads the
/// live `Intl.defaultLocale`) so a language switch flips the text on the next
/// rebuild — matching the old `Shop.displayName` getter behaviour exactly.
extension ShopDisplay on ShopEntity {
  String get displayName => localizedCatalogName(name, nameAr);
}
