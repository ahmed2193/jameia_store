import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/content_page_entity.dart';
import '../entities/offer_entity.dart';

/// Marketing content of the jm3eia backend (public routes).
abstract class PromotionsRepository {
  /// `GET /v1/offers?page&limit` — the active automatic cart promotions.
  Future<Either<Failure, List<OfferEntity>>> getOffers();

  /// `GET /v1/pages/:slug`.
  Future<Either<Failure, ContentPageEntity>> getContentPage(
    ContentPageKind kind,
  );
}
