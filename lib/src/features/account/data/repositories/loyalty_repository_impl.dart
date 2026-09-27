import 'package:dartz/dartz.dart';

import '../../../../core/data/mappers/loyalty_program_mapper.dart';
import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/data/repositories/cached_repository_mixin.dart';
import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/domain/entities/loyalty_program.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/ledger.dart';
import '../../domain/entities/loyalty_entry_entity.dart';
import '../../domain/repositories/loyalty_repository.dart';
import '../datasources/ledger_cache_data_source.dart';
import '../datasources/loyalty_remote_data_source.dart';
import '../mappers/loyalty_mapper.dart';

class LoyaltyRepositoryImpl
    with BaseRepositoryMixin, CachedRepositoryMixin
    implements LoyaltyRepository {
  const LoyaltyRepositoryImpl(this._remote, {required this._cache});

  final LoyaltyRemoteDataSource _remote;
  final LedgerCacheDataSource _cache;

  static const int _firstPage = 1;

  @override
  Stream<DataSnapshot<Ledger<LoyaltyEntryEntity>>> watchFirstPage({
    required int limit,
    bool forceRefresh = false,
  }) => cachedRead(
    cache: _cache.loyalty(limit: limit),
    fetch: () => _remote.getLedger(page: _firstPage, limit: limit),
    toEntity: (model) => model.toEntity(),
    forceRefresh: forceRefresh,
  );

  @override
  Future<Either<Failure, Ledger<LoyaltyEntryEntity>>> getLedger({
    required int page,
    required int limit,
  }) => execute(
    () async =>
        (await _remote.getLedger(page: page, limit: limit)).model.toEntity(),
  );

  @override
  Future<Either<Failure, LoyaltyProgram>> getProgram() =>
      execute(() async => (await _remote.getProgram()).toEntity());
}
