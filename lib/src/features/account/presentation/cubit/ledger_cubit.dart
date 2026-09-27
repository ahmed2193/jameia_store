import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../../../core/utils/performance/screen_loader_mixin.dart';
import '../../../../core/utils/performance/snapshot_loader_mixin.dart';
import '../../domain/entities/ledger.dart';
import '../../domain/entities/ledger_change.dart';
import '../../domain/entities/ledger_entry.dart';
import '../../domain/usecases/get_ledger_usecase.dart';
import '../../domain/usecases/watch_ledger_usecase.dart';
import 'ledger_state.dart';

/// Page-scoped cubit of a wallet / points history screen: the first page
/// (the device copy first, offline too, then the server's), pull-to-refresh
/// and the next pages. The list maths lives in `Ledger`, the screen flow in
/// the loader mixins; this only maps the pages.
class LedgerCubit<T extends LedgerEntry> extends Cubit<LedgerState<T>>
    with
        SafeCubitMixin<LedgerState<T>>,
        SnapshotLoaderMixin<LedgerState<T>>,
        ScreenLoaderMixin<LedgerState<T>>,
        PagedScreenMixin<LedgerState<T>> {
  LedgerCubit(this._watchFirstPage, this._getLedger) : super(LedgerState<T>());

  static const int pageSize = 20;

  final WatchLedgerUseCase<T> _watchFirstPage;
  final GetLedgerUseCase<T> _getLedger;

  /// First load (or retry after an error): the skeleton only while nothing
  /// is on screen, then page 1.
  Future<void> load() {
    showLoading();
    return _readFirstPage(forceRefresh: false);
  }

  /// Pull-to-refresh: the server's page 1 while the current list stays on
  /// screen. When the balance or the lines moved, [LedgerState.change] says
  /// how and [LedgerState.changeSerial] ticks (the screen plays the delta
  /// once).
  @override
  Future<void> refresh() => _readFirstPage(forceRefresh: true);

  Future<void> _readFirstPage({required bool forceRefresh}) =>
      readScreen<Ledger<T>>(
        _watchFirstPage(
          WatchLedgerParams(limit: pageSize, forceRefresh: forceRefresh),
        ),
        show: (state, snapshot) {
          final ledger = snapshot.data;
          // Only a list already on screen "changes" something the customer
          // watches — a refresh, or the server's answer over the saved copy;
          // a first load (or a retry) just appears.
          final change = state.isLoaded
              ? ledger.changeSince(state.ledger)
              : LedgerChange.none;
          final moved = !change.isEmpty;
          return state.copyWith(
            ledger: ledger,
            change: moved ? change : null,
            changeSerial: moved ? state.changeSerial + 1 : null,
          );
        },
      );

  /// Next page; a no-op while one is in flight, before the first load, when
  /// the server has no more, and after a failed page unless [retry].
  @override
  Future<void> loadMore({bool retry = false}) => loadNextPage<Ledger<T>>(
    hasMore: state.ledger.hasMore,
    retry: retry,
    fetch: () => _getLedger(
      GetLedgerParams(page: state.ledger.page + 1, limit: pageSize),
    ),
    merge: (state, next) => state.copyWith(ledger: state.ledger.merge(next)),
  );
}
