import '../../domain/entities/gathering_card_entity.dart';
import '../models/catalog.dart';

/// `GatheringCard` DTO → [GatheringCardEntity].
extension GatheringCardMapper on GatheringCard {
  GatheringCardEntity toEntity() => GatheringCardEntity(
    id: id,
    title: title,
    titleEn: titleEn,
    subtitle: subtitle,
    subtitleEn: subtitleEn,
    image: image,
    price: price,
    scheme: scheme,
  );
}

extension GatheringCardListMapper on List<GatheringCard> {
  List<GatheringCardEntity> toEntities() =>
      map((c) => c.toEntity()).toList(growable: false);
}
