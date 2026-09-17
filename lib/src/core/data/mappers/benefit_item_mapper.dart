import '../../domain/entities/benefit_item_entity.dart';
import '../models/catalog.dart';

/// `BenefitItem` DTO → [BenefitItemEntity].
extension BenefitItemMapper on BenefitItem {
  BenefitItemEntity toEntity() =>
      BenefitItemEntity(text: text, textEn: textEn, icon: icon, color: color);
}

extension BenefitItemListMapper on List<BenefitItem> {
  List<BenefitItemEntity> toEntities() =>
      map((b) => b.toEntity()).toList(growable: false);
}
