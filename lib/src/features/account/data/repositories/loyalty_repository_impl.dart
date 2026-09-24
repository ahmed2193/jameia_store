import 'package:dartz/dartz.dart';

import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/ledger.dart';
import '../../domain/entities/loyalty_entry_entity.dart';
import '../../domain/entities/loyalty_program.dart';
import '../../domain/repositories/loyalty_repository.dart';
import '../datasources/loyalty_remote_data_source.dart';
import '../mappers/loyalty_mapper.dart';

class LoyaltyRepositoryImpl
    with BaseRepositoryMixin
    implements LoyaltyRepository {
  const LoyaltyRepositoryImpl(this._remote);

  final LoyaltyRemoteDataSource _remote;

  @override
  Future<Either<Failure, Ledger<LoyaltyEntryEntity>>> getLedger({
    required int page,
    required int limit,
  }) => execute(
    () async => (await _remote.getLedger(page: page, limit: limit)).toEntity(),
  );

  @override
  Future<Either<Failure, LoyaltyProgram>> getProgram() =>
      execute(() async => (await _remote.getProgram()).toEntity());
}
