import '../../../../core/data/models/models.dart';
import '../../domain/entities/benefit_item_entity.dart';

/// DTO → entity mapping for the sticky-benefits-bar items. Raw bilingual text
/// resolved live in `presentation/util/benefit_item_display.dart`.
extension BenefitItemMapper on BenefitItem {
  BenefitItemEntity toEntity() => BenefitItemEntity(
        text: text,
        textEn: textEn,
        icon: icon,
        color: color,
      );
}

extension BenefitItemListMapper on List<BenefitItem> {
  List<BenefitItemEntity> toEntities() =>
      map((b) => b.toEntity()).toList();
}
