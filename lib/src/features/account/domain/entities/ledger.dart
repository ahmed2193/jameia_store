import 'package:equatable/equatable.dart';

import 'ledger_entry.dart';

/// The loaded pages of an account ledger plus the balance the server sent
/// with them: fils for the wallet (`GET /v1/account/wallet`), points for the
/// loyalty ledger (`GET /v1/account/loyalty`). The list arithmetic lives
/// here, not in the cubit.
class Ledger<T extends LedgerEntry> extends Equatable {
  const Ledger({
    required this.balance,
    required this.entries,
    required this.page,
    required this.hasMore,
  });

  const Ledger.empty()
    : balance = 0,
      entries = const <Never>[],
      page = 0,
      hasMore = false;

  final int balance;

  /// Newest first, as the server orders them.
  final List<T> entries;

  /// The last page loaded (1-based; 0 before the first).
  final int page;
  final bool hasMore;

  bool get isEmpty => entries.isEmpty;

  /// Appends [next] (a later page), dropping entries already shown — a line
  /// added meanwhile shifts the pages, so one may arrive twice. The balance
  /// is the newer one.
  Ledger<T> merge(Ledger<T> next) {
    final known = {for (final entry in entries) entry.id};
    return Ledger<T>(
      balance: next.balance,
      entries: [
        ...entries,
        for (final entry in next.entries)
          if (!known.contains(entry.id)) entry,
      ],
      page: next.page,
      hasMore: next.hasMore,
    );
  }

  @override
  List<Object?> get props => [balance, entries, page, hasMore];
}
