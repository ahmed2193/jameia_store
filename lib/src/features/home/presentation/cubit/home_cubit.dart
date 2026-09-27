import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/data_freshness.dart';
import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/watch_params.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../../../core/utils/performance/snapshot_loader_mixin.dart';
import '../../domain/entities/home_bootstrap.dart';
import '../../domain/entities/home_feed.dart';
import '../../domain/usecases/compose_home_feed_usecase.dart';
import '../../domain/usecases/mark_home_popups_shown_usecase.dart';
import '../../domain/usecases/select_due_home_popups_usecase.dart';
import '../../domain/usecases/watch_home_bootstrap_usecase.dart';
import '../../domain/usecases/watch_home_feed_usecase.dart';
import 'home_state.dart';

/// Page-scoped cubit of the home tab: the screen (`/v1/home`) and the launch
/// snapshot (`/v1/init`) are read side by side, each the device copy first
/// (no skeleton) and then the server's. The snapshot is secondary: its
/// failure never blanks the screen, and its saved copy never offers the
/// time-boxed popups.
class HomeCubit extends Cubit<HomeState>
    with SafeCubitMixin<HomeState>, SnapshotLoaderMixin<HomeState> {
  HomeCubit(
    this._watchFeed,
    this._composeFeed,
    this._watchBootstrap,
    this._selectDuePopups,
    this._markPopupsShown, {
    this._now = DateTime.now,
  }) : super(HomeState.initial());

  static const Object _feedChannel = #feed;
  static const Object _bootstrapChannel = #bootstrap;

  final WatchHomeFeedUseCase _watchFeed;
  final ComposeHomeFeedUseCase _composeFeed;
  final WatchHomeBootstrapUseCase _watchBootstrap;
  final SelectDueHomePopupsUseCase _selectDuePopups;
  final MarkHomePopupsShownUseCase _markPopupsShown;
  final DateTime Function() _now;

  /// First open, and "try again" after a full-screen error (skeleton). A
  /// saved copy paints at once; the server's replaces it when stale.
  Future<void> load() {
    if (state.status == HomeStatus.error) {
      safeEmit(state.copyWith(status: HomeStatus.loading));
    }
    return _read(WatchParams.cached);
  }

  /// Pull to refresh: the server's; the screen stays as it is meanwhile and a
  /// failure only surfaces as a transient [HomeState.failure].
  Future<void> refresh() => _read(WatchParams.fresh);

  /// The connection came back: one silent refresh when home shows a saved
  /// copy or failed.
  Future<void> onReconnected() => refreshOnReconnect(
    needed: state.freshness.isStale || state.status == HomeStatus.error,
    refresh: refresh,
  );

  /// Both reads start together; the returned future follows the feed.
  Future<void> _read(WatchParams params) {
    unawaited(
      followSnapshots<HomeBootstrap>(
        _watchBootstrap(params),
        channel: _bootstrapChannel,
        onSnapshot: _onBootstrap,
        onFailure: (_) {}, // secondary: home renders without it
      ),
    );
    return followSnapshots<HomeFeed>(
      _watchFeed(params),
      channel: _feedChannel,
      onSnapshot: _onFeed,
      onFailure: _onFeedFailure,
    );
  }

  void _onFeed(DataSnapshot<HomeFeed> snapshot) => safeEmit(
    state.copyWith(
      status: HomeStatus.loaded,
      feed: _compose(snapshot.data),
      freshness: DataFreshness.of(snapshot),
    ),
  );

  void _onFeedFailure(Failure failure) => safeEmit(
    state.copyWith(
      status: state.isLoaded ? HomeStatus.loaded : HomeStatus.error,
      freshness: state.freshness.failed(),
      failure: failure,
    ),
  );

  void _onBootstrap(DataSnapshot<HomeBootstrap> snapshot) => safeEmit(
    state.copyWith(
      bootstrap: snapshot.data,
      // Popups are time-boxed: never offered from a saved copy.
      duePopups: snapshot.isFromCache
          ? null
          : (state.popupsShown
                ? const <HomeMarketingPopup>[]
                : _duePopups(snapshot.data)),
    ),
  );

  /// The blocks the screen draws: expired strips dropped, a strip folded
  /// into the rail it advertises, the category block filled from the tree.
  HomeFeed _compose(HomeFeed feed) =>
      _composeFeed(ComposeHomeFeedParams(feed: feed, now: _now()))
          .getOrElse(() => feed);

  List<HomeMarketingPopup> _duePopups(HomeBootstrap bootstrap) =>
      _selectDuePopups(
        SelectDueHomePopupsParams(popups: bootstrap.popups, today: _now()),
      ).getOrElse(() => const <HomeMarketingPopup>[]);

  /// The page is about to show the popup queue: latch it (once per session)
  /// and stamp the once-a-day ones.
  void markPopupsShown() {
    if (!state.hasPendingPopups) return;
    final shown = state.duePopups;
    safeEmit(
      state.copyWith(
        popupsShown: true,
        duePopups: const <HomeMarketingPopup>[],
      ),
    );
    unawaited(
      _markPopupsShown(MarkHomePopupsShownParams(popups: shown, today: _now())),
    );
  }
}
