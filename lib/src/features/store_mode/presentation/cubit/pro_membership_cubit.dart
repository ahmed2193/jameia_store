import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/data_freshness.dart';
import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/usecase/watch_params.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../../../core/utils/performance/snapshot_loader_mixin.dart';
import '../../domain/entities/pro_membership.dart';
import '../../domain/usecases/cancel_pro_subscription_usecase.dart';
import '../../domain/usecases/subscribe_to_pro_usecase.dart';
import '../../domain/usecases/watch_pro_program_usecase.dart';
import '../../domain/usecases/watch_pro_subscription_usecase.dart';
import 'pro_membership_state.dart';

/// Pro membership page: the public programme (perks + plans) and, for a
/// signed-in customer, the current subscription, plus the plan the customer
/// is looking at (the page's plan tabs). Both are read side by side, each
/// the device copy first (offline too), then the server's; the page shows
/// once it knows both — never a paywall before it knows whether the
/// customer is a member. Subscribing and cancelling are money-related: they
/// wait for the server (no optimistic state), cannot fire twice, and no
/// reload asked for before or during one lands over its answer.
class ProMembershipCubit extends Cubit<ProMembershipState>
    with
        SafeCubitMixin<ProMembershipState>,
        SnapshotLoaderMixin<ProMembershipState> {
  ProMembershipCubit(
    this._watchProgram,
    this._watchSubscription,
    this._subscribe,
    this._cancel, {
    this._now = DateTime.now,
  }) : super(const ProMembershipState());

  static const Object _programChannel = #program;
  static const Object _subscriptionChannel = #subscription;

  final WatchProProgramUseCase _watchProgram;
  final WatchProSubscriptionUseCase _watchSubscription;
  final SubscribeToProUseCase _subscribe;
  final CancelProSubscriptionUseCase _cancel;

  /// Dates a subscribe / cancel answer (tests pin it).
  final DateTime Function() _now;

  /// Bumped by every load and around every subscribe / cancel: a snapshot
  /// whose number is no longer current belongs to a load asked for before
  /// the latest one, or before or during a money action, so it is dropped.
  int _generation = 0;

  /// First load, retry, language switch: the saved copies first (the page
  /// already on screen stays meanwhile), then the server's.
  Future<void> load() {
    if (!state.isLoaded) {
      safeEmit(state.copyWith(status: ProMembershipStatus.loading));
    }
    return _read(WatchParams.cached);
  }

  /// Pull to refresh: the server's; the page stays as it is meanwhile.
  Future<void> refresh() => _read(WatchParams.fresh);

  /// The connection came back: one silent refresh when the page shows a
  /// saved copy or failed.
  Future<void> onReconnected() => refreshOnReconnect(
    needed: () =>
        state.freshness.isStale || state.status == ProMembershipStatus.error,
    refresh: refresh,
  );

  /// Both reads start together; the returned future ends with the later.
  Future<void> _read(WatchParams params) {
    final generation = ++_generation;
    return Future.wait<void>([
      followSnapshots<ProProgram>(
        _watchProgram(params),
        channel: _programChannel,
        onSnapshot: (snapshot) {
          if (_isCurrent(generation)) _onProgram(snapshot);
        },
        onFailure: (failure) {
          if (_isCurrent(generation)) _onProgramFailure(failure);
        },
      ),
      followSnapshots<ProSubscription?>(
        _watchSubscription(params),
        channel: _subscriptionChannel,
        onSnapshot: (snapshot) {
          if (_isCurrent(generation)) _onSubscription(snapshot);
        },
        onFailure: (failure) {
          if (_isCurrent(generation)) _onSubscriptionFailure(failure);
        },
      ),
    ]);
  }

  /// A reply that lands during a subscribe / cancel, or that was asked for
  /// before or during one, would flip the buttons back on and overwrite the
  /// server's answer.
  bool _isCurrent(int generation) => generation == _generation && !state.isBusy;

  void _onProgram(DataSnapshot<ProProgram> snapshot) {
    final selection = _selectionFor(snapshot.data, state.subscription);
    safeEmit(
      state.copyWith(
        status: state.knowsMembership ? ProMembershipStatus.loaded : null,
        program: snapshot.data,
        programFreshness: DataFreshness.of(snapshot),
        selectedPlanId: selection,
        clearSelectedPlan: selection == null,
      ),
    );
  }

  /// The programme could not be read: one already here (the device copy,
  /// the page on screen) stays, marked stale; with none it is the error
  /// view (retry).
  void _onProgramFailure(Failure failure) {
    if (!state.knowsProgram) {
      safeEmit(
        state.copyWith(status: ProMembershipStatus.error, failure: failure),
      );
      return;
    }
    safeEmit(
      state.copyWith(
        programFreshness: state.programFreshness.failed(),
        failure: state.isLoaded ? failure : null,
      ),
    );
  }

  void _onSubscription(DataSnapshot<ProSubscription?> snapshot) {
    final subscription = snapshot.data;
    final selection = _selectionFor(state.program, subscription);
    safeEmit(
      state.copyWith(
        status: state.knowsProgram ? ProMembershipStatus.loaded : null,
        subscription: subscription,
        clearSubscription: subscription == null,
        isSignedOut: false,
        subscriptionFreshness: DataFreshness.of(snapshot),
        selectedPlanId: selection,
        clearSelectedPlan: selection == null,
      ),
    );
  }

  /// The subscription could not be read. A guest (401) still sees the
  /// plans. Any other failure: what we knew stays (sign-in state, the
  /// subscription — the device copy counts), marked stale; with nothing
  /// known the membership is unknown, so it is the error view (retry) —
  /// never a paywall that sells Pro to a member.
  void _onSubscriptionFailure(Failure failure) {
    if (failure is UnauthorizedFailure) {
      final selection = _selectionFor(state.program, null);
      safeEmit(
        state.copyWith(
          status: state.knowsProgram ? ProMembershipStatus.loaded : null,
          isSignedOut: true,
          clearSubscription: true,
          subscriptionFreshness: DataFreshness.none,
          selectedPlanId: selection,
          clearSelectedPlan: selection == null,
        ),
      );
      return;
    }
    if (!state.knowsMembership) {
      safeEmit(
        state.copyWith(status: ProMembershipStatus.error, failure: failure),
      );
      return;
    }
    safeEmit(
      state.copyWith(
        subscriptionFreshness: state.subscriptionFreshness.failed(),
        failure: state.isLoaded ? failure : null,
      ),
    );
  }

  /// Shows [planId] in the plan tabs. Ignored while an action is in flight,
  /// for a member (the tabs stay on the plan they own) or for a plan the
  /// programme does not sell.
  void selectPlan(String planId) {
    if (state.isBusy || state.isMember || planId == state.selectedPlanId) {
      return;
    }
    if (state.program.planById(planId) == null) return;
    safeEmit(state.copyWith(selectedPlanId: planId));
  }

  /// A member's own plan while the programme still sells it; otherwise keeps
  /// the current pick while the reloaded programme still sells it, otherwise
  /// opens on [ProProgram.initialPlan].
  String? _selectionFor(ProProgram program, ProSubscription? subscription) {
    final owned = (subscription?.hasBenefits ?? false)
        ? program.planById(subscription!.planId)
        : null;
    if (owned != null) return owned.id;
    final kept = program.planById(state.selectedPlanId);
    if (kept != null) return kept.id;
    return program.initialPlan()?.id;
  }

  Future<void> subscribe(String planId) async {
    if (state.isBusy || !state.isLoaded) return;
    // Any reload already in flight answers from before the subscribe …
    _generation++;
    safeEmit(state.copyWith(submittingPlanId: planId));
    final result = await _subscribe(SubscribeToProParams(planId));
    // … and one asked for while it ran may have been answered before it.
    _generation++;
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          clearSubmitting: true,
          isSignedOut: failure is UnauthorizedFailure ? true : null,
          failure: failure,
          actionFailed: true,
        ),
      ),
      (subscription) => safeEmit(
        state.copyWith(
          clearSubmitting: true,
          subscription: subscription,
          subscriptionFreshness: _answeredNow(),
          selectedPlanId: state.program.planById(subscription.planId)?.id,
          outcome: ProMembershipOutcome.subscribed,
        ),
      ),
    );
  }

  Future<void> cancelSubscription() async {
    if (state.isBusy || !(state.subscription?.canCancel ?? false)) return;
    // Any reload already in flight answers from before the cancel …
    _generation++;
    safeEmit(state.copyWith(isCancelling: true));
    final result = await _cancel(const NoParams());
    // … and one asked for while it ran may have been answered before it.
    _generation++;
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          isCancelling: false,
          failure: failure,
          actionFailed: true,
        ),
      ),
      (subscription) => safeEmit(
        state.copyWith(
          isCancelling: false,
          subscription: subscription,
          subscriptionFreshness: _answeredNow(),
          outcome: ProMembershipOutcome.cancelled,
        ),
      ),
    );
  }

  /// A subscribe / cancel reply is the server's subscription as of now.
  DataFreshness _answeredNow() => DataFreshness(fetchedAt: _now());
}
