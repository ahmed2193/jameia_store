import '../../domain/entities/jameia_category_entity.dart';
import '../jameia/jameia_models.dart';
import 'jameia_sub_category_mapper.dart';

/// `JameiaCategory` DTO → [JameiaCategoryEntity].
extension JameiaCategoryMapper on JameiaCategory {
  /// Full graph: sub-categories → ranks → products (shop page tabs).
  JameiaCategoryEntity toEntity() => JameiaCategoryEntity(
    id: id,
    name: name,
    nameAr: nameAr,
    image: image,
    subs: subs.toEntities(),
  );

  /// Top level only (id / name / artwork, `subs` left empty) — for surfaces
  /// that just list categories (home "Shop by category" rail), so they don't
  /// walk the whole product graph.
  JameiaCategoryEntity toSummaryEntity() =>
      JameiaCategoryEntity(id: id, name: name, nameAr: nameAr, image: image);
}

extension JameiaCategoryListMapper on List<JameiaCategory> {
  List<JameiaCategoryEntity> toEntities() =>
      map((c) => c.toEntity()).toList(growable: false);

  List<JameiaCategoryEntity> toSummaryEntities() =>
      map((c) => c.toSummaryEntity()).toList(growable: false);
}
