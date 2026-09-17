import '../../domain/entities/kingkong_item_entity.dart';
import '../models/catalog.dart';

/// `KingKongItem` DTO → [KingKongItemEntity].
extension KingKongItemMapper on KingKongItem {
  KingKongItemEntity toEntity() => KingKongItemEntity(
    id: id,
    title: title,
    titleAr: titleAr,
    icon: icon,
    color: color,
    image: image,
  );
}

extension KingKongItemListMapper on List<KingKongItem> {
  List<KingKongItemEntity> toEntities() =>
      map((k) => k.toEntity()).toList(growable: false);
}
