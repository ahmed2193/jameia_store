import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/data_freshness.dart';
import '../../../../core/domain/entities/screen_load.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/performance/screen_loader_mixin.dart';
import '../../domain/entities/ledger.dart';
import '../../domain/entities/ledger_change.dart';
import '../../domain/entities/ledger_entry.dart';

/// A wallet / points history screen: the loaded [ledger] and its paging.
class LedgerState<T extends LedgerEntry> extends Equatable
    implements ScreenLoadState<LedgerState<T>> {
  LedgerState({
    this.load = const ScreenLoad(),
    Ledger<T>? ledger,
    this.change = LedgerChange.none,
    this.changeSerial = 0,
  }) : ledger = ledger ?? Ledger<T>.empty();

  /// The first page's read, its freshness, the next page and the failure
  /// that goes with them.
  @override
  final ScreenLoad load;
  final Ledger<T> ledger;

  /// What the last refresh that moved something changed (balance delta, new
  /// lines) — a pull-to-refresh, or the server's answer over the saved copy;
  /// [LedgerChange.none] until then. Kept until the next such refresh — the
  /// screen reacts to [changeSerial], not to its value.
  final LedgerChange change;

  /// Bumped by every refresh that brought a [change]; each bump plays the
  /// balance delta / new-line highlight once.
  final int changeSerial;

  LoadPhase get status => load.phase;
  DataFreshness get freshness => load.freshness;
  Failure? get failure => load.failure;
  bool get isLoaded => load.isLoaded;
  bool get isLoadingMore => load.isLoadingMore;

  /// The last next-page request failed (the footer offers a retry; offline
  /// it waits for the connection).
  bool get loadMoreFailed => load.nextPageFailed;

  /// The customer route answered 401: the sign-in prompt, not an error.
  bool get isSignedOut => load.isSignedOut;

  @override
  LedgerState<T> withLoad(ScreenLoad load) => copyWith(load: load);

  LedgerState<T> copyWith({
    ScreenLoad? load,
    Ledger<T>? ledger,
    LedgerChange? change,
    int? changeSerial,
  }) => LedgerState<T>(
    load: load ?? this.load.settled(),
    ledger: ledger ?? this.ledger,
    change: change ?? this.change,
    changeSerial: changeSerial ?? this.changeSerial,
  );

  @override
  List<Object?> get props => [load, ledger, change, changeSerial];
}
