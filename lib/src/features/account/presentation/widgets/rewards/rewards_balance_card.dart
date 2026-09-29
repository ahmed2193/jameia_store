import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/rolling_number_text.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../domain/entities/loyalty_rewards.dart';
import 'rewards_next_tier.dart';
import 'rewards_star_badge.dart';

/// Warm amber → orange hero at the top of the Rewards screen: the balance
/// (there at once on open; it rolls only on a real change), what it is worth, the glowing star and — while a tier
/// is still locked — the progress toward the next one. Text is dark ink:
/// white on the light amber read at under 2:1.
class RewardsBalanceCard extends StatelessWidget {
  const RewardsBalanceCard({super.key, required this.rewards});

  final LoyaltyRewards rewards;

  static const List<Color> _gradient = [
    AppColors.proAmber,
    AppColors.accent3,
    kHeroPillPin,
  ];
  static const double _shadowAlpha = 0.22;
  static const Offset _shadowOffset = Offset(0, AppSpacing.s8);
  static final List<BoxShadow> _shadow = [
    BoxShadow(
      color: kHeroPillPin.withValues(alpha: _shadowAlpha),
      offset: _shadowOffset,
      blurRadius: AppSize.s24,
      spreadRadius: -AppSpacing.s6,
    ),
  ];
  static const double _mutedAlpha = 0.88;
  static final Color _muted = AppColors.primaryText.withValues(
    alpha: _mutedAlpha,
  );
  static const double _ringAlpha = 0.14;
  static final Color _ring = AppColors.white.withValues(alpha: _ringAlpha);
  static const double _ringOverhang = -AppSpacing.s48;
  static const double _ringWidth = AppSpacing.s24;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.r2);
    final worthKd = rewards.balanceValueKd;
    final locked = rewards.locked;
    final next = locked.isEmpty ? null : locked.first;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: _shadow,
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: _gradient,
        ),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            PositionedDirectional(
              top: _ringOverhang,
              end: _ringOverhang,
              child: SizedBox.square(
                dimension: AppSize.s180,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _ring, width: _ringWidth),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.s20,
                AppSpacing.s16,
                AppSpacing.s8,
                AppSpacing.s20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'loyalty.balance'.tr(),
                              style: AppTextStyles.subheadingMedium.copyWith(
                                color: _muted,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.s4),
                            RollingNumberText(
                              value: rewards.balance,
                              text: (points) => 'loyalty.points_value'.tr(
                                namedArgs: {'points': points},
                              ),
                              style: AppTextStyles.displayLarge.copyWith(
                                fontSize: AppSize.font40,
                                height: AppSize.lh1_2,
                                fontWeight: AppTextStyles.bold,
                                color: AppColors.primaryText,
                              ),
                            ),
                            if (worthKd > 0) ...[
                              const SizedBox(height: AppSpacing.s2),
                              Text(
                                'loyalty.worth'.tr(
                                  namedArgs: {
                                    'amount': Formatters.price(worthKd),
                                  },
                                ),
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: AppTextStyles.medium,
                                  color: _muted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const RewardsStarBadge(),
                    ],
                  ),
                  if (next != null) ...[
                    const SizedBox(height: AppSpacing.s16),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: AppSpacing.s12,
                      ),
                      child: RewardsNextTier(
                        balance: rewards.balance,
                        next: next,
                        missingPoints: rewards.missingFor(next),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
