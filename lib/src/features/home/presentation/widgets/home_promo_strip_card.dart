import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/responsive/app_size.dart';
import '../../domain/entities/home_section_entity.dart';
import 'home_accent_palette.dart';
import 'home_countdown_text.dart';

/// The call-out card itself: badge, headline, subtitle, a countdown when the
/// backend set an end, and a "Shop now" pill on the theme's fill.
///
/// It carries no outer padding — it is the head of a themed block as often as
/// it is a strip of its own, and each caller insets it.
class HomePromoStripCard extends StatelessWidget {
  const HomePromoStripCard({
    super.key,
    required this.section,
    required this.onTap,
  });

  final HomePromoStripSection section;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final endsAt = section.endsAt;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s14),
        decoration: BoxDecoration(
          color: HomeAccentPalette.stripFill(section.theme),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (section.badge.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpacing.s8,
                        vertical: AppSpacing.s2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.popupCloseScrim,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        section.badge,
                        style: AppTextStyles.captionSmall.copyWith(
                          color: AppColors.white,
                          fontWeight: AppTextStyles.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s6),
                  ],
                  Text(
                    section.headline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headingSmall.copyWith(
                      color: AppColors.white,
                      fontWeight: AppTextStyles.bold,
                    ),
                  ),
                  if (section.subtitle.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      section.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.captionLarge.copyWith(
                        color: AppColors.subtitleOverlay,
                      ),
                    ),
                  ],
                  if (endsAt != null) ...[
                    const SizedBox(height: AppSpacing.s6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'home.ends_in'.tr(),
                          style: AppTextStyles.captionLarge.copyWith(
                            color: AppColors.subtitleOverlay,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s4),
                        HomeCountdownText(
                          endsAt: endsAt,
                          style: AppTextStyles.digits(AppSize.font13).copyWith(
                            color: AppColors.white,
                            fontWeight: AppTextStyles.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            if (section.link.isNavigable)
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.s12,
                  vertical: AppSpacing.s8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'home.shop_now'.tr(),
                  style: AppTextStyles.captionLarge.copyWith(
                    color: AppColors.primaryText,
                    fontWeight: AppTextStyles.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
