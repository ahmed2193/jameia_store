import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/ledger.dart';
import '../entities/loyalty_entry_entity.dart';
import '../repositories/loyalty_repository.dart';
import 'get_ledger_usecase.dart';

/// One page of the points history: balance (points) + transactions.
class GetLoyaltyLedgerUseCase implements GetLedgerUseCase<LoyaltyEntryEntity> {
  const GetLoyaltyLedgerUseCase(this._repository);

  final LoyaltyRepository _repository;

  @override
  Future<Either<Failure, Ledger<LoyaltyEntryEntity>>> call(
    GetLedgerParams params,
  ) => _repository.getLedger(page: params.page, limit: params.limit);
}
