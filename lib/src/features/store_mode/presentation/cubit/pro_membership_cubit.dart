import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/pro_membership.dart';
import '../../domain/usecases/cancel_pro_subscription_usecase.dart';
import '../../domain/usecases/get_pro_program_usecase.dart';
import '../../domain/usecases/get_pro_subscription_usecase.dart';
import '../../domain/usecases/subscribe_to_pro_usecase.dart';
import 'pro_membership_state.dart';

/// Pro membership page: the public programme (perks + plans) and, for a
/// signed-in customer, the current subscription, plus the plan the customer
/// is looking at (the page's plan tabs). Subscribing and cancelling
/// are money-related: they wait for the server (no optimistic state), cannot
/// fire twice, and a background reload never interrupts them.
class ProMembershipCubit extends Cubit<ProMembershipState>
    with SafeCubitMixin<ProMembershipState> {
  ProMembershipCubit(
    this._getProgram,
    this._getSubscription,
    this._subscribe,
    this._cancel,
  ) : super(const ProMembershipState());

  final GetProProgramUseCase _getProgram;
  final GetProSubscriptionUseCase _getSubscription;
  final SubscribeToProUseCase _subscribe;
  final CancelProSubscriptionUseCase _cancel;

  /// Bumped by every [refresh] and by every subscribe / cancel: a reload
  /// whose number is no longer current started before the latest one or
  /// before a money action, so its reply is dropped.
  int _generation = 0;

  Future<void> load() async {
    if (!state.isLoaded) {
      safeEmit(state.copyWith(status: ProMembershipStatus.loading));
    }
    await refresh();
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    final (programResult, subscriptionResult) = await (
      _getProgram(const NoParams()),
      _getSubscription(const NoParams()),
    ).wait;
    // A reply that lands during a subscribe / cancel, or that was asked for
    // before one, would flip the buttons back on and overwrite the server's
    // answer: drop it.
    if (generation != _generation || state.isBusy) return;

    programResult.fold(
      (failure) => safeEmit(
        state.copyWith(
          status: state.isLoaded
              ? ProMembershipStatus.loaded
              : ProMembershipStatus.error,
          failure: failure,
        ),
      ),
      (program) => subscriptionResult.fold(
        (failure) => _subscriptionFailed(program, failure),
        (subscription) {
          final selection = _selectionFor(program, subscription);
          safeEmit(
            state.copyWith(
              status: ProMembershipStatus.loaded,
              program: program,
              subscription: subscription,
              clearSubscription: subscription == null,
              isSignedOut: false,
              selectedPlanId: selection,
              clearSelectedPlan: selection == null,
            ),
          );
        },
      ),
    );
  }

  /// The subscription read failed. A guest (401) still sees the plans. Any
  /// other failure means the membership is unknown: on the first load that
  /// is the error view (retry) — never a paywall that sells Pro to a member —
  /// and on a loaded page it keeps what we knew (sign-in state, subscription)
  /// and surfaces the failure.
  void _subscriptionFailed(ProProgram program, Failure failure) {
    final signedOut = failure is UnauthorizedFailure;
    if (!signedOut && !state.isLoaded) {
      safeEmit(
        state.copyWith(status: ProMembershipStatus.error, failure: failure),
      );
      return;
    }
    final selection = _selectionFor(
      program,
      signedOut ? null : state.subscription,
    );
    safeEmit(
      state.copyWith(
        status: ProMembershipStatus.loaded,
        program: program,
        isSignedOut: signedOut ? true : null,
        clearSubscription: signedOut,
        selectedPlanId: selection,
        clearSelectedPlan: selection == null,
        failure: signedOut ? null : failure,
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
    // Any reload already in flight answers from before the subscribe.
    _generation++;
    safeEmit(state.copyWith(submittingPlanId: planId));
    final result = await _subscribe(SubscribeToProParams(planId));
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          clearSubmitting: true,
          isSignedOut: failure is UnauthorizedFailure ? true : null,
          failure: failure,
        ),
      ),
      (subscription) => safeEmit(
        state.copyWith(
          clearSubmitting: true,
          subscription: subscription,
          selectedPlanId: state.program.planById(subscription.planId)?.id,
          outcome: ProMembershipOutcome.subscribed,
        ),
      ),
    );
  }

  Future<void> cancelSubscription() async {
    if (state.isBusy || !(state.subscription?.canCancel ?? false)) return;
    // Any reload already in flight answers from before the cancel.
    _generation++;
    safeEmit(state.copyWith(isCancelling: true));
    final result = await _cancel(const NoParams());
    result.fold(
      (failure) =>
          safeEmit(state.copyWith(isCancelling: false, failure: failure)),
      (subscription) => safeEmit(
        state.copyWith(
          isCancelling: false,
          subscription: subscription,
          outcome: ProMembershipOutcome.cancelled,
        ),
      ),
    );
  }
}
