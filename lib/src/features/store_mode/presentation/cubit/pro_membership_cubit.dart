import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/usecases/cancel_pro_subscription_usecase.dart';
import '../../domain/usecases/get_pro_program_usecase.dart';
import '../../domain/usecases/get_pro_subscription_usecase.dart';
import '../../domain/usecases/subscribe_to_pro_usecase.dart';
import 'pro_membership_state.dart';

/// Pro membership page: the public programme (perks + plans) and, for a
/// signed-in customer, the current subscription. Subscribing and cancelling
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
    // A reply that lands during a subscribe / cancel would flip the buttons
    // back on and overwrite the server's answer: drop it.
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
        // A guest (401) still sees the plans. Any other failure of this
        // secondary read keeps what we knew.
        (failure) => safeEmit(
          state.copyWith(
            status: ProMembershipStatus.loaded,
            program: program,
            isSignedOut: failure is UnauthorizedFailure,
            clearSubscription: failure is UnauthorizedFailure,
          ),
        ),
        (subscription) => safeEmit(
          state.copyWith(
            status: ProMembershipStatus.loaded,
            program: program,
            subscription: subscription,
            clearSubscription: subscription == null,
            isSignedOut: false,
          ),
        ),
      ),
    );
  }

  Future<void> subscribe(String planId) async {
    if (state.isBusy || !state.isLoaded) return;
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
          outcome: ProMembershipOutcome.subscribed,
        ),
      ),
    );
  }

  Future<void> cancelSubscription() async {
    if (state.isBusy || !(state.subscription?.canCancel ?? false)) return;
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
