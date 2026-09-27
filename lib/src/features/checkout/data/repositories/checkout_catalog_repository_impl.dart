import 'package:dartz/dartz.dart';

import '../../../../core/data/datasources/catalog_remote_data_source.dart';
import '../../../../core/data/mappers/catalog_product_mapper.dart';
import '../../../../core/data/mappers/offer_mapper.dart';
import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/domain/entities/offer_entity.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/checkout_catalog_repository.dart';
import '../datasources/checkout_rail_data_source.dart';

/// The checkout's catalogue reads: the deals rail through its short-lived
/// cache ([CheckoutRailDataSource]) and the store's offers over the shared
/// [CatalogRemoteDataSource] (cached for a few minutes and shared while in
/// flight, so the vouchers page and the checkout share one read).
class CheckoutCatalogRepositoryImpl
    with BaseRepositoryMixin
    implements CheckoutCatalogRepository {
  const CheckoutCatalogRepositoryImpl(this._rail, this._catalog);

  final CheckoutRailDataSource _rail;
  final CatalogRemoteDataSource _catalog;

  @override
  Future<Either<Failure, List<CatalogProductEntity>>> getRailProducts({
    required int limit,
  }) => execute(
    () async => (await _rail.getRailPage(limit: limit)).items.toEntities(),
  );

  @override
  Future<Either<Failure, List<OfferEntity>>> getStoreOffers() =>
      execute(() async => (await _catalog.getOffers()).toEntities());
}
