import 'package:dartz/dartz.dart';

import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/content_page_entity.dart';
import '../../domain/entities/offer_entity.dart';
import '../../domain/repositories/promotions_repository.dart';
import '../datasources/promotions_remote_data_source.dart';
import '../mappers/promotions_mapper.dart';

class PromotionsRepositoryImpl
    with BaseRepositoryMixin
    implements PromotionsRepository {
  const PromotionsRepositoryImpl(this._remote);

  final PromotionsRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<OfferEntity>>> getOffers() =>
      execute(() async => (await _remote.getOffers()).toEntities());

  @override
  Future<Either<Failure, ContentPageEntity>> getContentPage(
    ContentPageKind kind,
  ) => execute(() async => (await _remote.getPage(kind.slug)).toEntity(kind));
}
