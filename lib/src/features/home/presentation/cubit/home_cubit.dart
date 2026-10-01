import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/usecase/watch_params.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../../../core/utils/performance/screen_loader_mixin.dart';
import '../../../../core/utils/performance/snapshot_loader_mixin.dart';
import '../../domain/entities/home_bootstrap.dart';
import '../../domain/entities/home_feed.dart';
import '../../domain/usecases/check_first_order_welcome_usecase.dart';
import '../../domain/usecases/compose_home_feed_usecase.dart';
import '../../domain/usecases/mark_home_popups_shown_usecase.dart';
import '../../domain/usecases/select_due_home_popups_usecase.dart';
import '../../domain/usecases/watch_home_bootstrap_usecase.dart';
import '../../domain/usecases/watch_home_feed_usecase.dart';
import 'home_state.dart';

/// Page-scoped cubit of the home tab: the screen (`/v1/home`) and the launch
/// snapshot (`/v1/init`) are read side by side, each the device copy first
/// (no skeleton) and then the server's. The feed is the screen's read (the
/// loader mixins' flow); the snapshot is secondary: its failure never
/// blanks the screen, and its saved copy never offers the time-boxed popups.
/// The popup queue opens with the first-order welcome gift when the customer
/// is due it, then the marketing popups.
class HomeCubit extends Cubit<HomeState>
    with
        SafeCubitMixin<HomeState>,
        SnapshotLoaderMixin<HomeState>,
        ScreenLoaderMixin<HomeState> {
  HomeCubit(
    this._watchFeed,
    this._composeFeed,
    this._watchBootstrap,
    this._selectDuePopups,
    this._markPopupsShown,
    this._checkWelcome, {
    this._now = DateTime.now,
  }) : super(HomeState.initial());

  static const Object _bootstrapChannel = #bootstrap;

  final WatchHomeFeedUseCase _watchFeed;
  final ComposeHomeFeedUseCase _composeFeed;
  final WatchHomeBootstrapUseCase _watchBootstrap;
  final SelectDueHomePopupsUseCase _selectDuePopups;
  final MarkHomePopupsShownUseCase _markPopupsShown;
  final CheckFirstOrderWelcomeUseCase _checkWelcome;
  final DateTime Function() _now;

  /// Bumped per server snapshot: only the newest one's offer lands.
  int _popupOffer = 0;

  /// First open, and "try again" after a full-screen error (skeleton). A
  /// saved copy paints at once; the server's replaces it when stale.
  Future<void> load() {
    showLoading();
    return _read(WatchParams.cached);
  }

  /// Pull to refresh: the server's; the screen stays as it is meanwhile and a
  /// failure is told once over it.
  @override
  Future<void> refresh() => _read(WatchParams.fresh);

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
    return readScreen<HomeFeed>(
      _watchFeed(params),
      show: (state, snapshot) => state.copyWith(feed: _compose(snapshot.data)),
    );
  }

  void _onBootstrap(DataSnapshot<HomeBootstrap> snapshot) {
    safeEmit(state.copyWith(bootstrap: snapshot.data));
    // Popups are time-boxed: never offered from a saved copy.
    if (snapshot.isFromCache || state.popupsShown) return;
    unawaited(_offerPopups(snapshot.data));
  }

  /// Settles the welcome gift (maybe an order count) before the queue is
  /// offered, so it opens once, whole and in order. A newer snapshot's offer
  /// replaces one still waiting on its count.
  Future<void> _offerPopups(HomeBootstrap bootstrap) async {
    final offer = ++_popupOffer;
    final welcome = await _checkWelcome(
      CheckFirstOrderWelcomeParams(bootstrap: bootstrap),
    );
    if (offer != _popupOffer || state.popupsShown) return;
    safeEmit(
      state.copyWith(
        welcomeDue: welcome.fold((failure) {
          log('welcome gift unchecked', name: 'HomeCubit', error: failure);
          return false;
        }, (due) => due),
        duePopups: _duePopups(bootstrap),
      ),
    );
  }

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
        welcomeDue: false,
        duePopups: const <HomeMarketingPopup>[],
      ),
    );
    unawaited(
      _markPopupsShown(MarkHomePopupsShownParams(popups: shown, today: _now())),
    );
  }
}
