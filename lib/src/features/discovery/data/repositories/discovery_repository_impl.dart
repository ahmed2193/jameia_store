import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/shop_entity.dart';
import '../../domain/repositories/discovery_repository.dart';
import '../datasources/discovery_local_data_source.dart';
import '../mappers/shop_mapper.dart';

/// Offline discovery repository — reads the scripted [DiscoveryLocalDataSource]
/// and wraps each raw read in `Either<Failure, T>`. All derivation/sorting is
/// left to the use cases; this layer only exposes the catalogue.
class DiscoveryRepositoryImpl implements DiscoveryRepository {
  DiscoveryRepositoryImpl({required this.local});

  final DiscoveryLocalDataSource local;

  @override
  Future<Either<Failure, DiscoveryCatalogue>> catalogue() async {
    try {
      return Right((
        shops: local.allShops().toEntities(),
        filters: local.filters(),
      ));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ShopEntity>>> shops() async {
    try {
      return Right(local.allShops().toEntities());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ShopEntity>>> restaurants() async {
    try {
      return Right(local.restaurants().toEntities());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ShopEntity>>> groceries() async {
    try {
      return Right(local.groceries().toEntities());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ShopEntity>> shopById(String id) async {
    try {
      return Right(local.shopById(id).toEntity());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
