import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/responsive/app_size.dart';
import '../../domain/entities/home_bootstrap.dart';
import 'home_pro_perk_chip.dart';

/// The Pro membership call-out at the end of the home feed, built from the
/// perks the backend configured (`init.store.pro`).
class HomeProBanner extends StatelessWidget {
  const HomeProBanner({super.key, required this.pro, required this.onTap});

  final HomeProInfo pro;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.pageMargin,
        0,
        AppSpacing.pageMargin,
        AppSpacing.s8,
      ),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.s14),
          decoration: BoxDecoration(
            color: AppColors.primaryText,
            borderRadius: BorderRadius.circular(AppRadius.card),
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
                      'home.pro_title'.tr(),
                      style: AppTextStyles.headingSmall.copyWith(
                        color: AppColors.white,
                        fontWeight: AppTextStyles.bold,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: AppSize.s20,
                    color: AppColors.white,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                'home.pro_subtitle'.tr(),
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
    );
  }
}
