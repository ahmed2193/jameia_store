import '../../domain/entities/home_bootstrap.dart';
import '../models/home_init_model.dart';
import 'home_feed_mapper.dart';

/// [HomeInitModel] (wire) → [HomeBootstrap].
extension HomeBootstrapMapper on HomeInitModel {
  HomeBootstrap toEntity() => HomeBootstrap(
    storeName: storeName,
    tagline: tagline,
    delivery: delivery?.toEntity(),
    pro: HomeProInfo(
      enabled: proEnabled,
      freeDelivery: proFreeDelivery,
      pointsMultiplier: proPointsMultiplier,
      discountPercent: proDiscountPercent,
    ),
    popups: [for (final popup in popups) popup.toEntity()],
  );
}

extension HomeDeliveryMapper on HomeDeliveryModel {
  HomeDelivery toEntity() => HomeDelivery(
    mode: mode == HomeDeliveryModel.pickupMode
        ? HomeDeliveryMode.pickup
        : HomeDeliveryMode.delivery,
    branchName: branchName,
    zoneName: zoneName,
    etaMinutes: etaMinutes,
    deliveryFeeFils: deliveryFee,
    minOrderFils: minOrder,
    expressAvailable: expressAvailable,
  );
}

extension HomeMarketingPopupMapper on HomePopupModel {
  HomeMarketingPopup toEntity() => HomeMarketingPopup(
    id: id,
    title: title,
    body: body,
    imageUrl: imageUrl,
    ctaLabel: ctaLabel,
    link: HomeWire.link(linkType, linkTarget),
    frequency: frequency == HomePopupModel.dayFrequency
        ? HomePopupFrequency.day
        : HomePopupFrequency.session,
  );
}
