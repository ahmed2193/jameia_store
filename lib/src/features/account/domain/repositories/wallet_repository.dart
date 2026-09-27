import 'package:dartz/dartz.dart';

import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/error/failures.dart';
import '../entities/ledger.dart';
import '../entities/wallet_entry_entity.dart';

/// The customer's wallet on the jm3eia backend (customer Bearer):
/// https://docs.jm3eia.store/developers/account.html
abstract class WalletRepository {
  /// `GET /v1/account/wallet?page=1&limit` — the balance in fils plus the
  /// first page: the copy saved on the device first (offline too), then the
  /// server's (skipped while the copy is fresh, unless [forceRefresh]);
  /// failures on the error channel (`UnauthorizedFailure` when signed out).
  Stream<DataSnapshot<Ledger<WalletEntryEntity>>> watchFirstPage({
    required int limit,
    bool forceRefresh = false,
  });

  /// `GET /v1/account/wallet?page&limit` — the balance in fils plus one page
  /// of transactions, newest first, from the server only.
  /// `UnauthorizedFailure` when signed out.
  Future<Either<Failure, Ledger<WalletEntryEntity>>> getLedger({
    required int page,
    required int limit,
  });
}
