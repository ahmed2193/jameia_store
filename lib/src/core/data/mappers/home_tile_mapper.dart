import '../../domain/entities/home_tile_entity.dart';
import '../models/catalog.dart';

/// `HomeTile` DTO → [HomeTileEntity].
extension HomeTileMapper on HomeTile {
  HomeTileEntity toEntity() => HomeTileEntity(
    id: id,
    title: title,
    titleEn: titleEn,
    image: image,
    bg: bg,
    scheme: scheme,
  );
}

extension HomeTileListMapper on List<HomeTile> {
  List<HomeTileEntity> toEntities() =>
      map((t) => t.toEntity()).toList(growable: false);
}
