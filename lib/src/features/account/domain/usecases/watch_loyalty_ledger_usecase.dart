import '../../../../core/domain/entities/data_snapshot.dart';
import '../entities/ledger.dart';
import '../entities/loyalty_entry_entity.dart';
import '../repositories/loyalty_repository.dart';
import 'watch_ledger_usecase.dart';

/// The points history's first page: balance (points) + transactions, the
/// device copy first.
class WatchLoyaltyLedgerUseCase
    implements WatchLedgerUseCase<LoyaltyEntryEntity> {
  const WatchLoyaltyLedgerUseCase(this._repository);

  final LoyaltyRepository _repository;

  @override
  Stream<DataSnapshot<Ledger<LoyaltyEntryEntity>>> call(
    WatchLedgerParams params,
  ) => _repository.watchFirstPage(
    limit: params.limit,
    forceRefresh: params.forceRefresh,
  );
}
