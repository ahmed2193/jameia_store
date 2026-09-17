import 'package:easy_localization/easy_localization.dart';

import '../../../../core/data/models/models.dart' show localizedCatalogName;
import '../../domain/entities/shop_entity.dart';

/// Presentation-side, active-locale display for a [ShopEntity].
///
/// The entity carries raw bilingual fields; the visible name and the synthesized
/// promo tags / feature labels are resolved here so a language switch flips them
/// on the next rebuild — matching the old `Shop.displayName` / `Shop.displayTags`
/// / `Shop.displayFeatures` getters exactly.
extension ShopDisplay on ShopEntity {
  String get displayName => localizedCatalogName(name, nameAr);

  /// Promo tags to render — explicit [ShopEntity.promoTags] when present, else
  /// synthesized from shop state (max discount → "up to N% off", promo string,
  /// free-delivery coupon).
  List<PromoTagEntity> get displayTags {
    if (promoTags.isNotEmpty) return promoTags;
    final out = <PromoTagEntity>[];
    final maxOff = maxDiscountPercent;
    if (maxOff >= 5) {
      out.add(
        PromoTagEntity(
          text: 'catalog.up_to_off'.tr(namedArgs: {'percent': '$maxOff'}),
        ),
      );
    } else if (promo.isNotEmpty) {
      out.add(PromoTagEntity(text: promo));
    }
    if (freeDelivery) {
      out.add(
        PromoTagEntity(
          text: 'catalog.free_delivery'.tr(),
          bg: '#E2F6F0',
          fg: '#008C65',
          style: 'coupon',
        ),
      );
    }
    return out;
  }

  /// Feature labels — explicit [ShopEntity.featureLabels] when present, else
  /// first tags.
  List<String> get displayFeatures => featureLabels.isNotEmpty
      ? featureLabels
      : tags.take(2).toList(growable: false);
}
