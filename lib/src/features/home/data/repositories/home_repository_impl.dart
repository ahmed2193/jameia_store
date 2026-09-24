import 'package:dartz/dartz.dart';

import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/home_bootstrap.dart';
import '../../domain/entities/home_feed.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_local_data_source.dart';
import '../datasources/home_remote_data_source.dart';
import '../mappers/home_bootstrap_mapper.dart';
import '../mappers/home_feed_mapper.dart';

class HomeRepositoryImpl with BaseRepositoryMixin implements HomeRepository {
  const HomeRepositoryImpl(this._remote, this._local);

  final HomeRemoteDataSource _remote;
  final HomeLocalDataSource _local;

  @override
  Future<Either<Failure, HomeFeed>> getHomeFeed() =>
      execute(() async => (await _remote.getHome()).toEntity());

  @override
  Future<Either<Failure, HomeBootstrap>> getBootstrap() =>
      execute(() async => (await _remote.getInit()).toEntity());

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
