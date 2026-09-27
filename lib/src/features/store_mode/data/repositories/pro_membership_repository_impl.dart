import 'package:dartz/dartz.dart';

import '../../../../core/data/datasources/cache_slots.dart';
import '../../../../core/data/datasources/catalog_remote_data_source.dart';
import '../../../../core/data/mappers/catalog_taxonomy_mapper.dart';
import '../../../../core/data/models/remote_payload.dart';
import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/data/repositories/cached_repository_mixin.dart';
import '../../../../core/domain/entities/brand_entity.dart';
import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/pro_membership.dart';
import '../../domain/repositories/pro_membership_repository.dart';
import '../datasources/pro_membership_cache_data_source.dart';
import '../datasources/pro_membership_remote_data_source.dart';
import '../mappers/pro_membership_mapper.dart';
import '../models/pro_program_model.dart';
import '../models/pro_subscription_model.dart';

/// Every server answer about the programme or the subscription — a read, a
/// subscribe, a cancel — also becomes the device copy the Pro page opens
/// with, so a page reopened right after a subscribe never offers "join"
/// again (a fresh copy skips the request).
class ProMembershipRepositoryImpl
    with BaseRepositoryMixin, CachedRepositoryMixin
    implements ProMembershipRepository {
  const ProMembershipRepositoryImpl(
    this._remote,
    this._catalog, {
    required this._cache,
  });

  final ProMembershipRemoteDataSource _remote;

  /// The shared catalogue datasource — the paywall's brand rows read the
  /// same `GET /v1/brands` as search and discovery.
  final CatalogRemoteDataSource _catalog;
  final ProMembershipCacheDataSource _cache;

  static const int brandsPage = 1;

  /// Enough brands for the paywall's logo rows (the store lists 7 today).
  static const int brandsLimit = 20;

  @override
  Future<Either<Failure, ProProgram>> getProgram() => _answer(
    _cache.program(),
    _remote.getProgram,
    (model) => model.toEntity(),
  );

  @override
  Stream<DataSnapshot<ProProgram>> watchProgram({bool forceRefresh = false}) =>
      cachedRead<ProProgramModel, ProProgram>(
        cache: _cache.program(),
        fetch: _remote.getProgram,
        toEntity: (model) => model.toEntity(),
        forceRefresh: forceRefresh,
      );

  @override
  Future<Either<Failure, ProSubscription?>> getSubscription() => _answer(
    _cache.subscription(),
    _remote.getSubscription,
    (model) => model?.toEntity(),
  );

  @override
  Stream<DataSnapshot<ProSubscription?>> watchSubscription({
    bool forceRefresh = false,
  }) => cachedRead<ProSubscriptionModel?, ProSubscription?>(
    cache: _cache.subscription(),
    fetch: _remote.getSubscription,
    toEntity: (model) => model?.toEntity(),
    forceRefresh: forceRefresh,
  );

  @override
  Future<Either<Failure, ProSubscription>> subscribe(String planId) => _answer(
    _cache.subscription(),
    () => _remote.subscribe(planId),
    (model) => model.toEntity(),
  );

  @override
  Future<Either<Failure, ProSubscription>> cancel() => _answer(
    _cache.subscription(),
    _remote.cancel,
    (model) => model.toEntity(),
  );

  @override
  Future<Either<Failure, List<BrandEntity>>> getBrands() => execute(
    () async => (await _catalog.getBrands(
      page: brandsPage,
      limit: brandsLimit,
    )).toEntities(),
  );

  /// Runs [request] and keeps its answer as [cache]'s device copy — the slot
  /// is taken before the request, so a reply for an owner who changed
  /// meanwhile is not saved.
  Future<Either<Failure, E>> _answer<M, E>(
    CacheSlot<Object?>? cache,
    Future<RemotePayload<M>> Function() request,
    E Function(M model) toEntity,
  ) => execute(() async {
    final reply = await request();
    keepReply(cache, reply.raw);
    return toEntity(reply.model);
  });
}
