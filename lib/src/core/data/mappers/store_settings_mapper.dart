import '../../domain/entities/store_settings_entity.dart';
import '../../domain/entities/vip_card_entity.dart';
import '../jameia/jameia_models.dart';

/// `VipCard` DTO → [VipCardEntity].
extension VipCardMapper on VipCard {
  VipCardEntity toEntity() => VipCardEntity(
    titleEn: titleEn,
    titleAr: titleAr,
    descEn: descEn,
    descAr: descAr,
    image: image,
  );
}

/// `JameiaSettings` DTO → [StoreSettingsEntity].
extension JameiaSettingsMapper on JameiaSettings {
  StoreSettingsEntity toEntity() => StoreSettingsEntity(
    prepTime: prepTime,
    displayOrderAgain: displayOrderAgain,
    displayBestSelling: displayBestSelling,
    vip: vip.toEntity(),
    mart: mart.toEntity(),
  );
}
