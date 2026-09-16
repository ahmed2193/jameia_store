import '../../../../core/data/jameia/jameia_models.dart';
import '../../domain/entities/store_settings_entity.dart';

/// DTO → entity mapping for the store settings the VIP / Mart hero card needs.
extension VipCardMapper on VipCard {
  VipCardEntity toEntity() => VipCardEntity(
        titleEn: titleEn,
        titleAr: titleAr,
        descEn: descEn,
        descAr: descAr,
        image: image,
      );
}

extension JameiaSettingsMapper on JameiaSettings {
  StoreSettingsEntity toEntity() => StoreSettingsEntity(
        prepTime: prepTime,
        displayOrderAgain: displayOrderAgain,
        displayBestSelling: displayBestSelling,
        vip: vip.toEntity(),
        mart: mart.toEntity(),
      );
}
