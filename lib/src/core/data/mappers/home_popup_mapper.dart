import '../../domain/entities/home_popup_entity.dart';
import '../models/catalog.dart';

/// `HomePopup` DTO → [HomePopupEntity].
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
  List<HomePopupEntity> toEntities() =>
      map((p) => p.toEntity()).toList(growable: false);
}
