import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/ledger_entry.dart';
import '../../domain/usecases/get_ledger_usecase.dart';
import 'ledger_state.dart';

/// Page-scoped cubit of a wallet / points history screen: first page,
/// pull-to-refresh and the next pages. The list maths lives in `Ledger`;
/// this only sequences the calls.
class LedgerCubit<T extends LedgerEntry> extends Cubit<LedgerState<T>>
    with SafeCubitMixin<LedgerState<T>> {
  LedgerCubit(this._getLedger) : super(LedgerState<T>());

  static const int pageSize = 20;
  static const int _firstPage = 1;

  final GetLedgerUseCase<T> _getLedger;

  /// Bumped by every first-page load: a next page that was in flight when a
  /// newer first page started would append page N+1 onto a fresh page 1, so
  /// its reply is dropped.
  int _generation = 0;

  /// Bumped by every next-page request: once a refresh has reset the paging
  /// a newer request may own the "loading more" flag, and a stale reply must
  /// not clear it under that request.
  int _moreRequest = 0;

  /// First load (or retry after an error): full-screen loader, then page 1.
  Future<void> load() async {
    safeEmit(state.copyWith(status: LedgerStatus.loading));
    await _loadFirstPage(LedgerAction.load);
  }

  /// Pull-to-refresh: page 1 again while the current list stays on screen.
  Future<void> refresh() => _loadFirstPage(LedgerAction.refresh);

  Future<void> _loadFirstPage(LedgerAction action) async {
    final generation = ++_generation;
    final result = await _getLedger(
      const GetLedgerParams(page: _firstPage, limit: pageSize),
    );
    if (generation != _generation) return; // superseded by a newer load
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          // A failed refresh keeps the list; a failed first load has none.
          status: state.isLoaded ? LedgerStatus.loaded : LedgerStatus.error,
          failure: failure,
          failedAction: action,
        ),
      ),
      (ledger) => safeEmit(
        state.copyWith(
          status: LedgerStatus.loaded,
          ledger: ledger,
          isLoadingMore: false,
          loadMoreFailed: false,
        ),
      ),
    );
  }

  /// Next page; a no-op while one is in flight, before the first load, or
  /// when the server has no more.
  Future<void> loadMore() async {
    if (!state.isLoaded || !state.ledger.hasMore || state.isLoadingMore) {
      return;
    }
    final generation = _generation;
    final request = ++_moreRequest;
    safeEmit(state.copyWith(isLoadingMore: true, loadMoreFailed: false));
    final result = await _getLedger(
      GetLedgerParams(page: state.ledger.page + 1, limit: pageSize),
    );
    if (request != _moreRequest) return; // a newer next page owns the flag
    if (generation != _generation) {
      // A refresh replaced the list meanwhile: this page no longer follows it.
      safeEmit(state.copyWith(isLoadingMore: false));
      return;
    }
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          isLoadingMore: false,
          loadMoreFailed: true,
          failure: failure,
          failedAction: LedgerAction.loadMore,
        ),
      ),
      (next) => safeEmit(
        state.copyWith(isLoadingMore: false, ledger: state.ledger.merge(next)),
      ),
    );
  }
}
