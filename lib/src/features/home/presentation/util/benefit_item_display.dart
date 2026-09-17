import '../../../../core/data/models/models.dart' show localizedCatalogName;
import '../../domain/entities/benefit_item_entity.dart';

/// Presentation-side, active-locale display for a [BenefitItemEntity].
extension BenefitItemDisplay on BenefitItemEntity {
  String get displayText => localizedCatalogName(textEn, text);
}
