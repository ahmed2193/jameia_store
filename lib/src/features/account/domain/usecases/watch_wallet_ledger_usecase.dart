import '../../../../core/domain/entities/data_snapshot.dart';
import '../entities/ledger.dart';
import '../entities/wallet_entry_entity.dart';
import '../repositories/wallet_repository.dart';
import 'watch_ledger_usecase.dart';

/// The wallet's first page: balance (fils) + transactions, the device copy
/// first.
class WatchWalletLedgerUseCase
    implements WatchLedgerUseCase<WalletEntryEntity> {
  const WatchWalletLedgerUseCase(this._repository);

  final WalletRepository _repository;

  @override
  Stream<DataSnapshot<Ledger<WalletEntryEntity>>> call(
    WatchLedgerParams params,
  ) => _repository.watchFirstPage(
    limit: params.limit,
    forceRefresh: params.forceRefresh,
  );
}
