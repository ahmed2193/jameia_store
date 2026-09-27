import 'package:dartz/dartz.dart';

import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/domain/entities/loyalty_program.dart';
import '../../../../core/error/failures.dart';
import '../entities/ledger.dart';
import '../entities/loyalty_entry_entity.dart';

/// The customer's loyalty points and the store's programme on the jm3eia
/// backend: https://docs.jm3eia.store/developers/account.html
abstract class LoyaltyRepository {
  /// `GET /v1/account/loyalty?page=1&limit` — the points balance plus the
  /// first page: the copy saved on the device first (offline too), then the
  /// server's (skipped while the copy is fresh, unless [forceRefresh]);
  /// failures on the error channel (`UnauthorizedFailure` when signed out).
  Stream<DataSnapshot<Ledger<LoyaltyEntryEntity>>> watchFirstPage({
    required int limit,
    bool forceRefresh = false,
  });

  /// `GET /v1/account/loyalty?page&limit` (customer Bearer) — the points
  /// balance plus one page of transactions, newest first, from the server
  /// only. `UnauthorizedFailure` when signed out.
  Future<Either<Failure, Ledger<LoyaltyEntryEntity>>> getLedger({
    required int page,
    required int limit,
  });

  /// `GET /v1/init` → `store.loyalty` (public): earn / redeem rates and the
  /// bonuses. Loaded once per app run.
  Future<Either<Failure, LoyaltyProgram>> getProgram();
}
