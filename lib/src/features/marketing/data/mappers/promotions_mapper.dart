import '../../domain/entities/content_page_entity.dart';
import '../models/content_page_model.dart';

// The offer DTO and its mapper are shared with the product page: see
// `core/data/models/offer_model.dart` / `core/data/mappers/offer_mapper.dart`.

extension ContentPageMapper on ContentPageModel {
  ContentPageEntity toEntity(ContentPageKind kind) =>
      ContentPageEntity(kind: kind, title: title, body: body);
}
