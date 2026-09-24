import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/ledger.dart';
import '../entities/wallet_entry_entity.dart';

/// The customer's wallet on the jm3eia backend (customer Bearer):
/// https://docs.jm3eia.store/developers/account.html
abstract class WalletRepository {
  /// `GET /v1/account/wallet?page&limit` — the balance in fils plus one page
  /// of transactions, newest first. `UnauthorizedFailure` when signed out.
  Future<Either<Failure, Ledger<WalletEntryEntity>>> getLedger({
    required int page,
    required int limit,
  });
}
