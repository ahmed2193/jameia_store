import '../../../../core/data/jameia/jameia_models.dart';
import '../../domain/entities/jameia_category_entity.dart';

/// DTO → entity mapping for the home category rail. Keeps the core
/// `JameiaCategory`'s locale-live `displayName` out of the domain entity; the
/// raw bilingual name is resolved in `presentation/util/category_display.dart`.
extension JameiaCategoryMapper on JameiaCategory {
  JameiaCategoryEntity toEntity() =>
      JameiaCategoryEntity(id: id, name: name, nameAr: nameAr, image: image);
}

extension JameiaCategoryListMapper on List<JameiaCategory> {
  List<JameiaCategoryEntity> toEntities() => map((c) => c.toEntity()).toList();
}
