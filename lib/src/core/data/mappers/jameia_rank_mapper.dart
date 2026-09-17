import '../../domain/entities/jameia_rank_entity.dart';
import '../jameia/jameia_models.dart';
import 'product_mapper.dart';

/// `JameiaRank` DTO → [JameiaRankEntity].
extension JameiaRankMapper on JameiaRank {
  JameiaRankEntity toEntity() => JameiaRankEntity(
    id: id,
    name: name,
    nameAr: nameAr,
    image: image,
    count: count,
    products: products.toEntities(),
  );
}

extension JameiaRankListMapper on List<JameiaRank> {
  List<JameiaRankEntity> toEntities() =>
      map((r) => r.toEntity()).toList(growable: false);
}
