import 'package:dartz/dartz.dart';

import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/data/repositories/cached_repository_mixin.dart';
import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/home_bootstrap.dart';
import '../../domain/entities/home_feed.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_cache_data_source.dart';
import '../datasources/home_local_data_source.dart';
import '../datasources/home_remote_data_source.dart';
import '../mappers/home_bootstrap_mapper.dart';
import '../mappers/home_feed_mapper.dart';

class HomeRepositoryImpl
    with BaseRepositoryMixin, CachedRepositoryMixin
    implements HomeRepository {
  const HomeRepositoryImpl(this._remote, this._local, {required this._cache});

  final HomeRemoteDataSource _remote;
  final HomeLocalDataSource _local;
  final HomeCacheDataSource _cache;

  @override
  Stream<DataSnapshot<HomeFeed>> watchHomeFeed({bool forceRefresh = false}) =>
      cachedRead(
        cache: _cache.feed(),
        fetch: _remote.getHome,
        toEntity: (model) => model.toEntity(),
        forceRefresh: forceRefresh,
      );

  @override
  Stream<DataSnapshot<HomeBootstrap>> watchBootstrap({
    bool forceRefresh = false,
  }) => cachedRead(
    cache: _cache.init(),
    fetch: _remote.getInit,
    toEntity: (model) => model.toEntity(),
    forceRefresh: forceRefresh,
  );

  @override
  Future<Either<Failure, int>> countOrders() =>
      execute(() => _remote.countOrders());

  @override
  Either<Failure, String?> popupShownDay(String popupId) =>
      executeSync(() => _local.popupShownDay(popupId));

  @override
  Future<Either<Failure, Unit>> savePopupShownDay(String popupId, String day) =>
      execute(() async {
        await _local.savePopupShownDay(popupId, day);
        return unit;
      });
}
