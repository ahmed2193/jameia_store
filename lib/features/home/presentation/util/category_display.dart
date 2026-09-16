import '../../../../core/data/models/models.dart' show localizedCatalogName;
import '../../domain/entities/jameia_category_entity.dart';

/// Presentation-side, active-locale display for a [JameiaCategoryEntity].
extension JameiaCategoryDisplay on JameiaCategoryEntity {
  String get displayName => localizedCatalogName(name, nameAr);
}
