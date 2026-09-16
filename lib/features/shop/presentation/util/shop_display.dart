import '../../../../core/data/models/models.dart' show localizedCatalogName;
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/shop_entity.dart';

/// Presentation-side, active-locale display for the shop entities.
///
/// The entities are framework-free (raw bilingual fields only); resolving the
/// visible string is a presentation concern, so it lives here. Reuses the
/// catalogue's canonical locale picker (`localizedCatalogName`, which reads the
/// live `Intl.defaultLocale`) so a language switch flips the text on the next
/// rebuild — matching the old `Shop.displayName` / `Product.displayName`
/// getters exactly.
extension ShopDisplay on ShopEntity {
  String get displayName => localizedCatalogName(name, nameAr);
}

extension ProductDisplay on ProductEntity {
  String get displayName => localizedCatalogName(name, nameAr);
}
