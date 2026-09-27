import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../domain/entities/data_snapshot.dart';
import '../../domain/entities/screen_load.dart';
import '../../error/failures.dart';
import 'safe_cubit_mixin.dart';
import 'snapshot_loader_mixin.dart';

/// A screen state built around a [ScreenLoad]: what [ScreenLoaderMixin]
/// reads and moves.
abstract interface class ScreenLoadState<S> {
  ScreenLoad get load;

  /// This state with [load] in place of its own.
  S withLoad(ScreenLoad load);
}

/// The cubit half of the offline screen contract for one cached read,
/// written once:
///
///   * [showLoading] — the skeleton only while nothing is on screen;
///   * [readScreen] — every snapshot puts its data on screen with its
///     freshness; a failure keeps what is on screen (its freshness says the
///     refresh failed) or, with nothing, becomes the full-screen state;
///   * [onReconnected] — one silent [refresh] when the data on screen is a
///     saved copy or failed, never for a signed-out screen.
///
/// The cubit keeps only the mapping of its data ([readScreen]'s `show`).
mixin ScreenLoaderMixin<S extends ScreenLoadState<S>>
    on SafeCubitMixin<S>, SnapshotLoaderMixin<S> {
  /// Pull-to-refresh: the server's data; the screen stays as it is meanwhile.
  Future<void> refresh();

  /// A read starts: the skeleton, unless data is on screen.
  void showLoading() {
    final started = state.load.started();
    if (started != state.load) safeEmit(state.withLoad(started));
  }

  /// Follows a read of the screen's data: [show] puts each snapshot's data
  /// into the state (equal data changes only the freshness, so the lists
  /// that select their data do not rebuild). Completes when the read is
  /// over.
  Future<void> readScreen<T>(
    Stream<DataSnapshot<T>> source, {
    required S Function(S state, DataSnapshot<T> snapshot) show,
  }) => followSnapshots<T>(
    source,
    onSnapshot: (snapshot) =>
        safeEmit(show(state, snapshot).withLoad(state.load.arrived(snapshot))),
    onFailure: (failure) =>
        safeEmit(state.withLoad(state.load.failedWith(failure))),
  );

  /// Something beside the read failed (an action, one row re-read): told
  /// once over the data on screen.
  void noteFailure(Failure failure, {FailedCall on = FailedCall.action}) =>
      safeEmit(state.withLoad(state.load.noted(failure, on: on)));

  /// The connection came back: one silent refresh when the screen shows a
  /// saved copy or failed.
  Future<void> onReconnected() => refreshOnReconnect(
    needed: () => state.load.needsRefresh,
    refresh: refresh,
  );
}

/// The next pages of a paged screen, written once (rule C.8):
///
///   * [loadNextPage] asks for one page at a time, never again after a
///     failure until [retry] (the footer's retry, the returning connection),
///     and drops a reply that no longer follows the list (page 1 was read
///     again meanwhile);
///   * a next page asked for while page 1 is still being read (a saved copy
///     checked with the server) waits for that read: merging it into the
///     copy would lose it when the server's page 1 replaces the copy;
///   * [onReconnected] refreshes a stale or failed page 1, then asks again
///     for the next page the footer still owes.
mixin PagedScreenMixin<S extends ScreenLoadState<S>> on ScreenLoaderMixin<S> {
  /// Bumped by every read of page 1: a next page asked for before it
  /// follows the old list.
  int _generation = 0;

  /// Bumped by every next-page request: only the latest may clear the
  /// "loading more" flag.
  int _pageRequest = 0;

  /// A next page was asked for while page 1 was being read.
  bool _pageOwed = false;

  /// The list's next page; [retry] asks again after a failed one.
  Future<void> loadMore({bool retry = false});

  @override
  Future<void> readScreen<T>(
    Stream<DataSnapshot<T>> source, {
    required S Function(S state, DataSnapshot<T> snapshot) show,
  }) {
    _generation++;
    return super.readScreen<T>(source, show: show).whenComplete(_askOwedPage);
  }

  /// Asks for the page after the one on screen with [fetch] and puts it on
  /// screen with [merge]. A no-op before page 1 is loaded, when there is no
  /// more ([hasMore]), while a page is on its way, and after a failed page
  /// unless [retry].
  Future<void> loadNextPage<P>({
    required bool hasMore,
    required Future<Either<Failure, P>> Function() fetch,
    required S Function(S state, P page) merge,
    bool retry = false,
  }) async {
    final load = state.load;
    if (!load.isLoaded || !hasMore || load.isLoadingMore) return;
    if (load.nextPageFailed && !retry) return;
    if (isReading()) {
      _pageOwed = true;
      return;
    }
    final generation = _generation;
    final request = ++_pageRequest;
    safeEmit(state.withLoad(load.nextPageStarted()));
    final result = await fetch();
    if (request != _pageRequest) return; // a newer page owns the flag
    if (generation != _generation) {
      // Page 1 was read again meanwhile: this page follows the old list.
      safeEmit(state.withLoad(state.load.nextPageDone()));
      return;
    }
    result.fold(
      (failure) =>
          safeEmit(state.withLoad(state.load.nextPageFailedWith(failure))),
      (page) =>
          safeEmit(merge(state, page).withLoad(state.load.nextPageDone())),
    );
  }

  @override
  Future<void> onReconnected() => refreshOnReconnect(
    needed: () => state.load.needsRefresh || state.load.nextPageFailed,
    refresh: () async {
      final pageOwed = state.load.nextPageFailed;
      if (state.load.needsRefresh) await refresh();
      if (pageOwed) await loadMore(retry: true);
    },
  );

  void _askOwedPage() {
    if (!_pageOwed || isClosed || isReading()) return;
    _pageOwed = false;
    unawaited(loadMore());
  }
}
