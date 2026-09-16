import '../../../../core/data/models/models.dart';
import '../../domain/entities/home_tile_entity.dart';

/// DTO → entity mapping for the "tiles area" tiles. Raw bilingual title resolved
/// live in `presentation/util/home_tile_display.dart`.
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
  List<HomeTileEntity> toEntities() => map((t) => t.toEntity()).toList();
}
