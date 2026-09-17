import '../../domain/entities/home_banner_entity.dart';
import '../models/catalog.dart';

/// `HomeBanner` DTO → [HomeBannerEntity].
extension HomeBannerMapper on HomeBanner {
  HomeBannerEntity toEntity() => HomeBannerEntity(
    id: id,
    title: title,
    titleAr: titleAr,
    subtitle: subtitle,
    itemCount: itemCount,
    image: image,
    bg: bg,
  );
}

extension HomeBannerListMapper on List<HomeBanner> {
  List<HomeBannerEntity> toEntities() =>
      map((b) => b.toEntity()).toList(growable: false);
}
