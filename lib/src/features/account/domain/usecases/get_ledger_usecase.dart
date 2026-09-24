import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/ledger.dart';
import '../entities/ledger_entry.dart';

class GetLedgerParams extends Equatable {
  const GetLedgerParams({required this.page, required this.limit});

  /// 1-based.
  final int page;

  /// Backend cap: 100.
  final int limit;

  @override
  List<Object?> get props => [page, limit];
}

/// One page of an account ledger (wallet or loyalty points), so one cubit
/// and one list serve both screens.
abstract class GetLedgerUseCase<T extends LedgerEntry>
    implements UseCase<Ledger<T>, GetLedgerParams> {}
