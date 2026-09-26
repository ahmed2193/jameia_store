import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../domain/entities/loyalty_reward.dart';
import '../../../domain/entities/loyalty_rewards.dart';
import 'rewards_grid_row.dart';

/// Two-column sliver of reward cards. Laid out row by row (not a fixed-extent
/// grid) so a row grows with a two-line title or a larger text scale.
class RewardsGrid extends StatelessWidget {
  const RewardsGrid({
    super.key,
    required this.items,
    required this.rewards,
    required this.firstIndex,
    required this.onRedeemed,
  });

  /// The cards of this section, smallest first.
  final List<LoyaltyReward> items;

  /// The whole screen (the balance a locked card counts from).
  final LoyaltyRewards rewards;

  /// Cascade position of this section's first card on the screen.
  final int firstIndex;

  /// A tier of this section was applied to the basket.
  final VoidCallback onRedeemed;

  static const int columns = 2;

  /// At most this many cards idle-float at once (the screen's loop budget).
  static const int maxFloating = 4;

  @override
  Widget build(BuildContext context) {
    final rowCount = (items.length + columns - 1) ~/ columns;
    return SliverPadding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s16,
      ),
      sliver: SliverList.separated(
        itemCount: rowCount,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s20),
        itemBuilder: (_, row) {
          final start = row * columns;
          final end = start + columns;
          return RewardsGridRow(
            items: items.sublist(
              start,
              end < items.length ? end : items.length,
            ),
            rewards: rewards,
            firstIndex: firstIndex + start,
            onRedeemed: onRedeemed,
          );
        },
      ),
    );
  }
}
