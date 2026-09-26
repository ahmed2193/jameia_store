import 'package:equatable/equatable.dart';

import 'loyalty_program.dart';
import 'loyalty_reward.dart';

/// The Rewards screen: the customer's points [balance] and the redemption
/// tiers the loyalty [program] allows.
///
/// The tiers are an APP choice, not backend data: jm3eia has no rewards
/// catalogue. The server redeems any number of points at or above
/// [LoyaltyProgram.minRedeemPoints] as a discount on the current basket
/// (`POST /v1/cart/loyalty {points}`), each point worth
/// [LoyaltyProgram.redemptionPerPoint] fils. The screen offers fixed steps of
/// that minimum — [tierMultipliers] × the step — so the customer picks a
/// discount like a voucher instead of typing a number.
class LoyaltyRewards extends Equatable {
  const LoyaltyRewards({
    required this.balance,
    required this.program,
    required this.rewards,
  });

  /// The tiers the programme allows for [balance]; none when the store does
  /// not run a programme or a point is worth nothing.
  factory LoyaltyRewards.from(LoyaltyProgram program, int balance) {
    if (!program.enabled || program.redemptionPerPoint <= 0) {
      return LoyaltyRewards(
        balance: balance,
        program: program,
        rewards: const [],
      );
    }
    final step = program.minRedeemPoints > 0
        ? program.minRedeemPoints
        : fallbackStep;
    return LoyaltyRewards(
      balance: balance,
      program: program,
      rewards: [
        for (final multiplier in tierMultipliers)
          LoyaltyReward(
            points: step * multiplier,
            valueFils: step * multiplier * program.redemptionPerPoint,
          ),
      ],
    );
  }

  /// Nothing loaded yet.
  static const LoyaltyRewards none = LoyaltyRewards(
    balance: 0,
    program: LoyaltyProgram.none,
    rewards: [],
  );

  /// The tier step when the programme sets no redemption minimum.
  static const int fallbackStep = 100;

  /// The tiers offered, as multiples of the step (app choice, see the class
  /// doc).
  static const List<int> tierMultipliers = [1, 2, 5, 10];

  final int balance;
  final LoyaltyProgram program;

  /// Smallest first.
  final List<LoyaltyReward> rewards;

  bool get isAvailable => rewards.isNotEmpty;

  /// The tiers the balance already covers.
  List<LoyaltyReward> get ready => [
    for (final reward in rewards)
      if (reward.points <= balance) reward,
  ];

  /// The tiers still out of reach.
  List<LoyaltyReward> get locked => [
    for (final reward in rewards)
      if (reward.points > balance) reward,
  ];

  /// Points still to earn before [reward] can be redeemed; 0 when ready.
  int missingFor(LoyaltyReward reward) {
    final missing = reward.points - balance;
    return missing > 0 ? missing : 0;
  }

  /// The discount the whole balance is worth, in dinar.
  double get balanceValueKd => program.valueKdOf(balance);

  @override
  List<Object?> get props => [balance, program, rewards];
}
