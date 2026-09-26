import 'package:dartz/dartz.dart';

import '../../../../core/data/datasources/catalog_remote_data_source.dart';
import '../../../../core/data/mappers/offer_mapper.dart';
import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/domain/entities/offer_entity.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/product_detail.dart';
import '../../domain/entities/product_reviews.dart';
import '../../domain/repositories/product_details_repository.dart';
import '../datasources/product_details_remote_data_source.dart';
import '../mappers/product_detail_mapper.dart';

class ProductDetailsRepositoryImpl
    with BaseRepositoryMixin
    implements ProductDetailsRepository {
  const ProductDetailsRepositoryImpl(this._remote, this._catalog);

  final ProductDetailsRemoteDataSource _remote;

  /// The shared catalogue reads (the offers list).
  final CatalogRemoteDataSource _catalog;

  @override
  Future<Either<Failure, ProductDetail>> getProduct(String slug) =>
      execute(() async => (await _remote.getProduct(slug)).toEntity());

  @override
  Future<Either<Failure, ProductReviews>> getReviews({
    required String slug,
    required int page,
    required int limit,
  }) => execute(
    () async => (await _remote.getReviews(
      slug: slug,
      page: page,
      limit: limit,
    )).toEntity(),
  );

  @override
  Future<Either<Failure, List<OfferEntity>>> getOffers() =>
      execute(() async => (await _catalog.getOffers()).toEntities());
}
