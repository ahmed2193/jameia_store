import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/responsive/app_size.dart';
import '../../domain/entities/pro_membership.dart';
import 'pro_perk_row.dart';

/// Hero card of the Pro page: what a member gets, as the backend configured it.
class ProPerksCard extends StatelessWidget {
  const ProPerksCard({super.key, required this.perks, required this.isMember});

  final ProPerks perks;
  final bool isMember;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.s12),
      padding: const EdgeInsets.all(AppSpacing.s16),
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
                size: AppSize.s28,
                color: AppColors.accent4,
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Text(
                  'pro.title'.tr(),
                  style: AppTextStyles.headingLarge.copyWith(
                    color: AppColors.white,
                    fontWeight: AppTextStyles.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            isMember ? 'pro.member_subtitle'.tr() : 'pro.subtitle'.tr(),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.subtitleOverlay,
            ),
          ),
          if (perks.freeDelivery)
            ProPerkRow(
              icon: Icons.local_shipping_outlined,
              label: 'pro.perk_free_delivery'.tr(),
            ),
          if (perks.hasPointsBoost)
            ProPerkRow(
              icon: Icons.stars_rounded,
              label: 'pro.perk_points'.tr(
                namedArgs: {'multiplier': '${perks.pointsMultiplier}'},
              ),
            ),
          if (perks.hasDiscount)
            ProPerkRow(
              icon: Icons.percent_rounded,
              label: 'pro.perk_discount'.tr(
                namedArgs: {'percent': '${perks.discountPercent}'},
              ),
            ),
          ProPerkRow(
            icon: Icons.sell_outlined,
            label: 'pro.perk_member_prices'.tr(),
          ),
        ],
      ),
    );
  }
}
