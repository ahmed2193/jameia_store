import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/ledger.dart';
import '../entities/ledger_entry.dart';

class WatchLedgerParams extends Equatable {
  const WatchLedgerParams({required this.limit, this.forceRefresh = false});

  /// Backend cap: 100.
  final int limit;

  /// Pull to refresh / reconnect: skip the saved copy.
  final bool forceRefresh;

  @override
  List<Object?> get props => [limit, forceRefresh];
}

/// The first page of an account ledger (wallet or loyalty points), the
/// balance with it: the copy saved on the device first, then the server's;
/// failures on the error channel — so one cubit and one list serve both
/// screens. The next pages are `GetLedgerUseCase`'s — never kept.
abstract class WatchLedgerUseCase<T extends LedgerEntry>
    implements StreamUseCase<DataSnapshot<Ledger<T>>, WatchLedgerParams> {}
