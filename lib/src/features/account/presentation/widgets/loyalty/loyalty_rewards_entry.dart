import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/press_scale.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';
import '../../../../../core/widgets/light_sweep.dart';
import '../rewards/rewards_gift_badge.dart';

/// "Redeem your points" tile under the balance card: opens the Rewards
/// screen. A warm cream → peach card with the gift gently floating in an
/// amber badge; a shine sweeps across it once in a while ([LightSweep],
/// never under reduced motion).
class LoyaltyRewardsEntry extends StatelessWidget {
  const LoyaltyRewardsEntry({super.key});

  static const double _arrowDisc = AppSize.s28;
  static const double _borderAlpha = 0.28;
  static final Color _border = AppColors.accent3.withValues(
    alpha: _borderAlpha,
  );
  static const List<Color> _tile = [kHeroPromoCream, AppColors.accent3Light];

  /// White on cream reads faint: a brighter band than the default.
  static const double _shineAlpha = 0.8;

  /// One sweep at the default [AppMotion.sheen] pace every [_shinePeriod]
  /// (two sheens); the rest of the period the tile is still.
  static final Duration _shinePeriod = AppMotion.sheen * 2;
  static const double _shineShare = LightSweep.defaultSweepShare / 2;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.r3);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s16,
        0,
        AppSpacing.s16,
        AppSpacing.s16,
      ),
      child: Semantics(
        button: true,
        child: PressScale(
          onTap: () => context.push(Routes.loyaltyRewards),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: _border),
              gradient: const LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: _tile,
              ),
            ),
            child: LightSweep(
              period: _shinePeriod,
              sweepShare: _shineShare,
              peakAlpha: _shineAlpha,
              borderRadius: radius,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s14),
                child: Row(
                  children: [
                    const RewardsGiftBadge(),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'loyalty.rewards_entry'.tr(),
                            style: AppTextStyles.headingSmall.copyWith(
                              fontWeight: AppTextStyles.bold,
                              color: AppColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s2),
                          Text(
                            'loyalty.rewards_entry_body'.tr(),
                            style: AppTextStyles.captionLarge.copyWith(
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox.square(
                        dimension: _arrowDisc,
                        child: HeroIcon(
                          HeroIcons.chevronEnd,
                          size: AppSize.s14,
                          color: AppColors.accent3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
