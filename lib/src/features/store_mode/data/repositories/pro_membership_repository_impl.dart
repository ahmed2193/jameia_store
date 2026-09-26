import 'package:dartz/dartz.dart';

import '../../../../core/data/datasources/catalog_remote_data_source.dart';
import '../../../../core/data/mappers/catalog_taxonomy_mapper.dart';
import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/domain/entities/brand_entity.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/pro_membership.dart';
import '../../domain/repositories/pro_membership_repository.dart';
import '../datasources/pro_membership_remote_data_source.dart';
import '../mappers/pro_membership_mapper.dart';

class ProMembershipRepositoryImpl
    with BaseRepositoryMixin
    implements ProMembershipRepository {
  const ProMembershipRepositoryImpl(this._remote, this._catalog);

  final ProMembershipRemoteDataSource _remote;

  /// The shared catalogue datasource — the paywall's brand rows read the
  /// same `GET /v1/brands` as search and discovery.
  final CatalogRemoteDataSource _catalog;

  static const int brandsPage = 1;

  /// Enough brands for the paywall's logo rows (the store lists 7 today).
  static const int brandsLimit = 20;

  @override
  Future<Either<Failure, ProProgram>> getProgram() =>
      execute(() async => (await _remote.getProgram()).toEntity());

  @override
  Future<Either<Failure, ProSubscription?>> getSubscription() =>
      execute(() async => (await _remote.getSubscription())?.toEntity());

  @override
  Future<Either<Failure, ProSubscription>> subscribe(String planId) =>
      execute(() async => (await _remote.subscribe(planId)).toEntity());

  @override
  Future<Either<Failure, ProSubscription>> cancel() =>
      execute(() async => (await _remote.cancel()).toEntity());

  @override
  Future<Either<Failure, List<BrandEntity>>> getBrands() => execute(
    () async => (await _catalog.getBrands(
      page: brandsPage,
      limit: brandsLimit,
    )).toEntities(),
  );
}
