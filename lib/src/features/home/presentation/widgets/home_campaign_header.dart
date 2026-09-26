import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../domain/entities/home_section_entity.dart';
import 'home_accent_palette.dart';
import 'home_arrow_button.dart';
import 'home_layout.dart';
import 'home_strip_badge.dart';
import 'home_strip_countdown.dart';

/// The head of a campaign block, drawn from the strip the backend configured:
/// badge, headline in the theme's strong colour, subtitle and countdown on
/// the block's light band, and the round arrow that opens the campaign.
class HomeCampaignHeader extends StatelessWidget {
  const HomeCampaignHeader({
    super.key,
    required this.strip,
    required this.onTap,
  });

  final HomePromoStripSection strip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strong = HomeAccentPalette.stripFill(strip.theme);
    final endsAt = strip.endsAt;
    final navigable = strip.link.isNavigable;
    return Semantics(
      button: navigable,
      child: GestureDetector(
        onTap: navigable ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: HomeLayout.gutter,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (strip.badge.isNotEmpty) ...[
                      HomeStripBadge(
                        label: strip.badge,
                        fill: strong,
                        ink: AppColors.white,
                        beat: endsAt != null,
                      ),
                      const SizedBox(height: AppSpacing.s6),
                    ],
                    Text(
                      strip.headline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.displaySmall.copyWith(
                        color: strong,
                        fontWeight: AppTextStyles.bold,
                      ),
                    ),
                    if (strip.subtitle.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s2),
                      Text(
                        strip.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.captionLarge.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                    if (endsAt != null) ...[
                      const SizedBox(height: AppSpacing.s6),
                      HomeStripCountdown(
                        endsAt: endsAt,
                        labelColor: AppColors.secondaryText,
                        digitsColor: strong,
                      ),
                    ],
                  ],
                ),
              ),
              if (navigable) ...[
                const SizedBox(width: AppSpacing.s12),
                HomeArrowButton(
                  onTap: onTap,
                  label: 'home.shop_now'.tr(),
                  size: HomeArrowButton.largeSize,
                  nudge: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
