import '../../../../core/data/models/models.dart';
import '../../domain/entities/gathering_card_entity.dart';

/// DTO → entity mapping for the "gathering" carousel cards. Raw bilingual
/// title/subtitle are resolved live in
/// `presentation/util/gathering_card_display.dart`.
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
      map((c) => c.toEntity()).toList();
}
