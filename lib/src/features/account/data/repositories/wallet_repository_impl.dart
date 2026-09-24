import 'package:dartz/dartz.dart';

import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/ledger.dart';
import '../../domain/entities/wallet_entry_entity.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_data_source.dart';
import '../mappers/wallet_mapper.dart';

class WalletRepositoryImpl
    with BaseRepositoryMixin
    implements WalletRepository {
  const WalletRepositoryImpl(this._remote);

  final WalletRemoteDataSource _remote;

  @override
  Future<Either<Failure, Ledger<WalletEntryEntity>>> getLedger({
    required int page,
    required int limit,
  }) => execute(
    () async => (await _remote.getLedger(page: page, limit: limit)).toEntity(),
  );
}
