import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/domain/entities/offer_entity.dart';
import '../entities/content_page_entity.dart';

/// Marketing content of the Hero backend (public routes): the copy saved
/// on the device first (offline too), then the server's (skipped while the
/// copy is fresh, unless `forceRefresh`); failures on the error channel.
abstract class PromotionsRepository {
  /// `GET /v1/offers` — the automatic cart promotions (ended ones included:
  /// what is still running is the use case's rule).
  Stream<DataSnapshot<List<OfferEntity>>> watchOffers({
    bool forceRefresh = false,
  });

  /// `GET /v1/pages/:slug`.
  Stream<DataSnapshot<ContentPageEntity>> watchContentPage(
    ContentPageKind kind, {
    bool forceRefresh = false,
  });
}
