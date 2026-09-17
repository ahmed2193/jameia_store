import '../../domain/entities/promo_tag_entity.dart';
import '../models/shop.dart';

/// `PromoTag` DTO → [PromoTagEntity].
extension PromoTagMapper on PromoTag {
  PromoTagEntity toEntity() =>
      PromoTagEntity(text: text, bg: bg, fg: fg, style: style);
}

extension PromoTagListMapper on List<PromoTag> {
  List<PromoTagEntity> toEntities() =>
      map((t) => t.toEntity()).toList(growable: false);
}
