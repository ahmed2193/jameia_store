import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/light_sweep.dart';
import '../../domain/entities/home_bootstrap.dart';
import 'home_layout.dart';
import 'home_pro_perk_chip.dart';
import 'home_reveal_scope.dart';

/// The Pro offer at the end of the home feed, for everyone without the perks:
/// the perks the backend configured (`init.store.pro`) on the Pro violet,
/// with a "Join Pro" pill — for a [lapsed] member "Come back to Jm3eia Pro"
/// and "Rejoin". A soft shine sweeps across it now and then while it is on
/// screen.
class HomeProOfferBanner extends StatelessWidget {
  const HomeProOfferBanner({
    super.key,
    required this.pro,
    required this.onTap,
    this.lapsed = false,
  });

  final HomeProInfo pro;
  final VoidCallback onTap;

  /// Was a member; the membership ran out.
  final bool lapsed;

  /// Strength of the shine on the violet.
  static const double _shineAlpha = 0.22;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(HomeLayout.radius);
    return Semantics(
      button: true,
      child: PressScale(
        onTap: onTap,
        child: LightSweep(
          peakAlpha: _shineAlpha,
          active: HomeRevealScope.onScreenOf(context),
          // The shine is cut at the rounded corners.
          borderRadius: radius,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.s14),
            decoration: BoxDecoration(
              color: AppColors.accentViolet,
              borderRadius: radius,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.workspace_premium_rounded,
                      size: AppSize.s20,
                      color: AppColors.accent4,
                    ),
                    const SizedBox(width: AppSpacing.s6),
                    Expanded(
                      child: Text(
                        (lapsed ? 'home.pro_lapsed_title' : 'home.pro_title')
                            .tr(),
                        style: AppTextStyles.headingSmall.copyWith(
                          color: AppColors.white,
                          fontWeight: AppTextStyles.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpacing.s10,
                        vertical: AppSpacing.s4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        (lapsed ? 'home.pro_rejoin_cta' : 'home.pro_join_cta')
                            .tr(),
                        maxLines: 1,
                        style: AppTextStyles.captionLarge.copyWith(
                          color: AppColors.accentViolet,
                          fontWeight: AppTextStyles.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  (lapsed ? 'home.pro_lapsed_subtitle' : 'home.pro_subtitle')
                      .tr(),
                  style: AppTextStyles.captionLarge.copyWith(
                    color: AppColors.subtitleOverlay,
                  ),
                ),
                const SizedBox(height: AppSpacing.s10),
                Wrap(
                  spacing: AppSpacing.s6,
                  runSpacing: AppSpacing.s6,
                  children: [
                    if (pro.freeDelivery)
                      HomeProPerkChip(label: 'home.pro_free_delivery'.tr()),
                    if (pro.hasPointsBoost)
                      HomeProPerkChip(
                        label: 'home.pro_points'.tr(
                          namedArgs: {'multiplier': '${pro.pointsMultiplier}'},
                        ),
                      ),
                    if (pro.hasDiscount)
                      HomeProPerkChip(
                        label: 'home.pro_discount'.tr(
                          namedArgs: {'percent': '${pro.discountPercent}'},
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
