import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/ledger.dart';
import '../entities/wallet_entry_entity.dart';
import '../repositories/wallet_repository.dart';
import 'get_ledger_usecase.dart';

/// One page of the wallet: balance (fils) + transactions.
class GetWalletLedgerUseCase implements GetLedgerUseCase<WalletEntryEntity> {
  const GetWalletLedgerUseCase(this._repository);

  final WalletRepository _repository;

  @override
  Future<Either<Failure, Ledger<WalletEntryEntity>>> call(
    GetLedgerParams params,
  ) => _repository.getLedger(page: params.page, limit: params.limit);
}
