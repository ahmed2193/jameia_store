import '../../../../core/data/models/models.dart';
import '../../domain/entities/home_popup_entity.dart';

/// DTO → entity mapping for the home popup queue. Raw bilingual title/body/CTA/
/// amount-unit resolved live in `presentation/util/home_popup_display.dart`.
extension HomePopupMapper on HomePopup {
  HomePopupEntity toEntity() => HomePopupEntity(
        id: id,
        type: type,
        image: image,
        title: title,
        titleEn: titleEn,
        body: body,
        bodyEn: bodyEn,
        ctaText: ctaText,
        ctaTextEn: ctaTextEn,
        scheme: scheme,
        amount: amount,
        amountUnit: amountUnit,
        amountUnitEn: amountUnitEn,
      );
}

extension HomePopupListMapper on List<HomePopup> {
  List<HomePopupEntity> toEntities() => map((p) => p.toEntity()).toList();
}
