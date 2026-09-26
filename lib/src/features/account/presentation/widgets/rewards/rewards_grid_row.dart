import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../domain/entities/loyalty_reward.dart';
import '../../../domain/entities/loyalty_rewards.dart';
import 'reward_card.dart';
import 'rewards_grid.dart';

/// One row of the two-column reward grid; a short last row keeps its card
/// at column width.
class RewardsGridRow extends StatelessWidget {
  const RewardsGridRow({
    super.key,
    required this.items,
    required this.rewards,
    required this.firstIndex,
    required this.onRedeemed,
  });

  /// Up to [RewardsGrid.columns] cards.
  final List<LoyaltyReward> items;
  final LoyaltyRewards rewards;

  /// Cascade position of this row's first card on the screen.
  final int firstIndex;
  final VoidCallback onRedeemed;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var column = 0; column < RewardsGrid.columns; column++) ...[
          if (column > 0) const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: column < items.length
                ? RewardCard(
                    key: ValueKey<int>(items[column].points),
                    reward: items[column],
                    missingPoints: rewards.missingFor(items[column]),
                    balance: rewards.balance,
                    entranceIndex: firstIndex + column,
                    floats: firstIndex + column < RewardsGrid.maxFloating,
                    onRedeemed: onRedeemed,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }
}
