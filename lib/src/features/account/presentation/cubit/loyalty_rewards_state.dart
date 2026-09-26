import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/loyalty_rewards.dart';

enum LoyaltyRewardsStatus { initial, loading, loaded, error }

/// The Rewards screen: the points balance and the redemption tiers.
class LoyaltyRewardsState extends Equatable {
  const LoyaltyRewardsState({
    this.status = LoyaltyRewardsStatus.initial,
    this.rewards = LoyaltyRewards.none,
    this.failure,
  });

  final LoyaltyRewardsStatus status;
  final LoyaltyRewards rewards;

  /// The last failure, cleared by the next [copyWith]. With [status] error
  /// it is what the error / sign-in view shows; on a loaded screen it is a
  /// failed pull-to-refresh (toasted, the tiers stay).
  final Failure? failure;

  bool get isLoaded => status == LoyaltyRewardsStatus.loaded;

  /// The points route answered 401: the sign-in prompt, not an error.
  bool get isSignedOut =>
      status == LoyaltyRewardsStatus.error && failure is UnauthorizedFailure;

  LoyaltyRewardsState copyWith({
    LoyaltyRewardsStatus? status,
    LoyaltyRewards? rewards,
    Failure? failure,
  }) => LoyaltyRewardsState(
    status: status ?? this.status,
    rewards: rewards ?? this.rewards,
    failure: failure,
  );

  @override
  List<Object?> get props => [status, rewards, failure];
}
