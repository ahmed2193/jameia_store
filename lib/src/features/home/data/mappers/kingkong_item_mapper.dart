import '../../../../core/data/models/models.dart';
import '../../domain/entities/kingkong_item_entity.dart';

/// DTO → entity mapping for KingKong grid tiles. Raw bilingual title is resolved
/// live in `presentation/util/kingkong_display.dart`.
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
  List<KingKongItemEntity> toEntities() => map((k) => k.toEntity()).toList();
}
