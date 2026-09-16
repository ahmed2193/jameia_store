import 'package:dartz/dartz.dart';

import '../../../../core/data/jameia/jameia_models.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/shop_entity.dart';
import '../../domain/repositories/shop_repository.dart';
import '../datasources/shop_local_data_source.dart';
import '../mappers/shop_mapper.dart';

/// Offline shop repository — reads the in-memory [ShopLocalDataSource] DTOs and,
/// for the shop-detail panel, maps them to a framework-free [ShopEntity]. The
/// favourites feed and the sync menu reads deliberately stay in core DTOs (see
/// [ShopRepository] — cross-feature / core-widget boundaries).
class ShopRepositoryImpl implements ShopRepository {
  ShopRepositoryImpl({required this.local});

  final ShopLocalDataSource local;

  @override
  Future<Either<Failure, ShopEntity>> getShopDetail(String shopId) async {
    try {
      return Right(local.shopDetail(shopId).toEntity());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Shop>>> getFavoriteShops() async {
    try {
      return Right(local.favoriteShops());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Shop? shopById(String id) => local.shopById(id);

  @override
  JameiaCategory? categoryById(String id) => local.categoryById(id);
}
