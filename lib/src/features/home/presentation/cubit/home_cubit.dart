import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/home_bootstrap.dart';
import '../../domain/entities/home_feed.dart';
import '../../domain/usecases/compose_home_feed_usecase.dart';
import '../../domain/usecases/get_home_bootstrap_usecase.dart';
import '../../domain/usecases/get_home_feed_usecase.dart';
import '../../domain/usecases/mark_home_popups_shown_usecase.dart';
import '../../domain/usecases/select_due_home_popups_usecase.dart';
import 'home_state.dart';

/// Page-scoped cubit of the home tab. One load = the screen (`/v1/home`) and
/// the launch snapshot (`/v1/init`) fetched together and emitted ONCE, so the
/// feed does not rebuild twice. The snapshot is secondary: its failure never
/// blanks the screen.
class HomeCubit extends Cubit<HomeState> with SafeCubitMixin<HomeState> {
  HomeCubit(
    this._getHomeFeed,
    this._composeFeed,
    this._getBootstrap,
    this._selectDuePopups,
    this._markPopupsShown, {
    this._now = DateTime.now,
  }) : super(HomeState.initial());

  final GetHomeFeedUseCase _getHomeFeed;
  final ComposeHomeFeedUseCase _composeFeed;
  final GetHomeBootstrapUseCase _getBootstrap;
  final SelectDueHomePopupsUseCase _selectDuePopups;
  final MarkHomePopupsShownUseCase _markPopupsShown;
  final DateTime Function() _now;

  /// Bumped by every load; a reply from an older generation is stale.
  int _generation = 0;

  /// First load (and retry after a full-screen error): shows the skeleton.
  Future<void> load() async {
    if (!state.isLoaded) safeEmit(state.copyWith(status: HomeStatus.loading));
    await refresh();
  }

  /// Pull-to-refresh / coming back to the tab: the content stays on screen and
  /// a failure only surfaces as a transient [HomeState.failure].
  Future<void> refresh() async {
    final generation = ++_generation;
    final (feedResult, bootstrapResult) = await (
      _getHomeFeed(const NoParams()),
      _getBootstrap(const NoParams()),
    ).wait;
    if (generation != _generation) return;

    final bootstrap = bootstrapResult.getOrElse(() => state.bootstrap);
    feedResult.fold(
      (failure) => safeEmit(
        state.copyWith(
          status: state.isLoaded ? HomeStatus.loaded : HomeStatus.error,
          bootstrap: bootstrap,
          failure: failure,
        ),
      ),
      (feed) => safeEmit(
        state.copyWith(
          status: HomeStatus.loaded,
          feed: _compose(feed),
          bootstrap: bootstrap,
          duePopups: state.popupsShown
              ? const <HomeMarketingPopup>[]
              : _duePopups(bootstrap),
        ),
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
        duePopups: const <HomeMarketingPopup>[],
      ),
    );
    unawaited(
      _markPopupsShown(MarkHomePopupsShownParams(popups: shown, today: _now())),
    );
  }
}
