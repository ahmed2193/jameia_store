import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/usecases/get_loyalty_rewards_usecase.dart';
import 'loyalty_rewards_state.dart';

/// Page-scoped cubit of the Rewards screen: loads the balance + tiers and
/// reloads them on pull-to-refresh. Redeeming is the app-global cart's job
/// (`CartCubit.applyLoyalty`).
class LoyaltyRewardsCubit extends Cubit<LoyaltyRewardsState>
    with SafeCubitMixin<LoyaltyRewardsState> {
  LoyaltyRewardsCubit(this._getRewards) : super(const LoyaltyRewardsState());

  final GetLoyaltyRewardsUseCase _getRewards;

  /// Bumped by every request: only the newest reply lands.
  int _generation = 0;

  /// First load (or retry after an error): the full-screen loader only when
  /// nothing is on screen yet.
  Future<void> load() async {
    if (!state.isLoaded) {
      safeEmit(state.copyWith(status: LoyaltyRewardsStatus.loading));
    }
    await refresh();
  }

  /// Pull-to-refresh: the tiers stay on screen; a failure keeps them.
  Future<void> refresh() async {
    // Drop the last refresh's failure first: the same failure again would
    // otherwise build an equal state, which is never emitted (no toast).
    // Only on a loaded screen: the error view keeps its failure.
    if (state.isLoaded && state.failure != null) safeEmit(state.copyWith());
    final generation = ++_generation;
    final result = await _getRewards(const NoParams());
    if (generation != _generation) return; // superseded by a newer request
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          status: state.isLoaded
              ? LoyaltyRewardsStatus.loaded
              : LoyaltyRewardsStatus.error,
          failure: failure,
        ),
      ),
      (rewards) => safeEmit(
        state.copyWith(status: LoyaltyRewardsStatus.loaded, rewards: rewards),
      ),
    );
  }
}
