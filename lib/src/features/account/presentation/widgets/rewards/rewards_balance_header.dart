import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';
import '../../../domain/entities/loyalty_rewards.dart';
import 'rewards_balance_card.dart';
import 'rewards_history_link.dart';

/// Top of the Rewards screen (rises in once): the balance card, then how
/// redeeming works next to the link to the points history.
class RewardsBalanceHeader extends StatelessWidget {
  const RewardsBalanceHeader({super.key, required this.rewards});

  final LoyaltyRewards rewards;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s16,
        AppSpacing.s16,
        AppSpacing.s16,
        AppSpacing.s4,
      ),
      child: ScrollReveal(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RewardsBalanceCard(rewards: rewards),
            const SizedBox(height: AppSpacing.s16),
            Row(
              children: [
                const HeroIcon(
                  HeroIcons.info,
                  size: AppSize.s16,
                  color: AppColors.tertiaryText,
                ),
                const SizedBox(width: AppSpacing.s6),
                Expanded(
                  child: Text(
                    'loyalty.rewards_how'.tr(),
                    style: AppTextStyles.captionLarge.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                const RewardsHistoryLink(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
