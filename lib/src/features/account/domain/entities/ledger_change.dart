import 'package:equatable/equatable.dart';

/// What a newer first page of a ledger brought compared with the one on
/// screen (`Ledger.changeSince`): how far the balance moved and which lines
/// were not there before. A pull-to-refresh uses it to show the balance
/// delta and to mark the new lines once.
class LedgerChange extends Equatable {
  const LedgerChange({this.balanceDelta = 0, this.newEntryIds = const {}});

  /// Nothing moved.
  static const LedgerChange none = LedgerChange();

  /// Newer balance minus the older one (fils for the wallet, points for the
  /// loyalty ledger); negative when it dropped.
  final int balanceDelta;

  /// Ids of the lines the newer page has and the older list did not.
  final Set<String> newEntryIds;

  bool get isEmpty => balanceDelta == 0 && newEntryIds.isEmpty;

  bool get balanceRose => balanceDelta > 0;

  @override
  List<Object?> get props => [balanceDelta, newEntryIds];
}
