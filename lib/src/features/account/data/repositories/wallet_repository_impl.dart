import 'package:dartz/dartz.dart';

import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/data/repositories/cached_repository_mixin.dart';
import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/ledger.dart';
import '../../domain/entities/wallet_entry_entity.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/ledger_cache_data_source.dart';
import '../datasources/wallet_remote_data_source.dart';
import '../mappers/wallet_mapper.dart';

class WalletRepositoryImpl
    with BaseRepositoryMixin, CachedRepositoryMixin
    implements WalletRepository {
  const WalletRepositoryImpl(this._remote, {required this._cache});

  final WalletRemoteDataSource _remote;
  final LedgerCacheDataSource _cache;

  static const int _firstPage = 1;

  @override
  Stream<DataSnapshot<Ledger<WalletEntryEntity>>> watchFirstPage({
    required int limit,
    bool forceRefresh = false,
  }) => cachedRead(
    cache: _cache.wallet(limit: limit),
    fetch: () => _remote.getLedger(page: _firstPage, limit: limit),
    toEntity: (model) => model.toEntity(),
    forceRefresh: forceRefresh,
  );

  @override
  Future<Either<Failure, Ledger<WalletEntryEntity>>> getLedger({
    required int page,
    required int limit,
  }) => execute(
    () async =>
        (await _remote.getLedger(page: page, limit: limit)).model.toEntity(),
  );
}
