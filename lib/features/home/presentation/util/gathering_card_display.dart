import '../../../../core/data/models/models.dart' show localizedCatalogName;
import '../../domain/entities/gathering_card_entity.dart';

/// Presentation-side, active-locale display for a [GatheringCardEntity].
/// Source stores Arabic/default in `title`/`subtitle` and English in the `*En`
/// fields; `localizedCatalogName(en, ar)` picks the right one for the locale.
extension GatheringCardDisplay on GatheringCardEntity {
  String get displayTitle => localizedCatalogName(titleEn, title);
  String get displaySubtitle => localizedCatalogName(subtitleEn, subtitle);
}
