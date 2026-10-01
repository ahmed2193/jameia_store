import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/hero_icon.dart';
import '../../../domain/entities/loyalty_reward.dart';
import 'reward_progress_bar.dart';

/// Bottom of the balance card: how far the balance is from the smallest
/// locked tier — a white bar filling up to it and "180 more points to unlock
/// KD 0.500 off" in dark ink (white text on the amber card fails contrast).
class RewardsNextTier extends StatelessWidget {
  const RewardsNextTier({
    super.key,
    required this.balance,
    required this.next,
    required this.missingPoints,
  });

  final int balance;

  /// The smallest tier the balance does not cover yet.
  final LoyaltyReward next;
  final int missingPoints;

  static const double _trackAlpha = 0.3;
  static final Color _track = AppColors.white.withValues(alpha: _trackAlpha);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RewardProgressBar(
          current: balance,
          target: next.points,
          height: AppSize.s8,
          trackColor: _track,
          fillColors: const [AppColors.white],
        ),
        const SizedBox(height: AppSpacing.s10),
        Row(
          children: [
            const HeroIcon(
              HeroIcons.lock,
              size: AppSize.s14,
              color: AppColors.primaryText,
            ),
            const SizedBox(width: AppSpacing.s6),
            Expanded(
              child: Text(
                'loyalty.rewards_next'.tr(
                  namedArgs: {
                    'points': '$missingPoints',
                    'amount': Formatters.price(next.valueKd),
                  },
                ),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primaryText,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
