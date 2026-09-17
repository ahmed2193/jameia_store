import '../../../../core/data/models/models.dart' show localizedCatalogName;
import '../../domain/entities/home_popup_entity.dart';

/// Presentation-side, active-locale display for a [HomePopupEntity].
extension HomePopupDisplay on HomePopupEntity {
  String get displayTitle => localizedCatalogName(titleEn, title);
  String get displayBody => localizedCatalogName(bodyEn, body);
  String get displayCta => localizedCatalogName(ctaTextEn, ctaText);
  String get displayAmountUnit =>
      localizedCatalogName(amountUnitEn, amountUnit);
}
