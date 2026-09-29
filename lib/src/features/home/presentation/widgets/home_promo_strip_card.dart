import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/widgets/light_sweep.dart';
import '../../domain/entities/home_section_entity.dart';
import 'home_accent_palette.dart';
import 'home_arrow_button.dart';
import 'home_layout.dart';
import 'home_strip_badge.dart';
import 'home_strip_countdown.dart';

/// A call-out as a full-bleed band in the theme's saturated colour ("Flash
/// deals — up to 30% off"): badge, big headline, subtitle, a countdown when
/// the backend set an end, and the round arrow when it leads somewhere.
/// While on screen a soft shine sweeps across it now and then, a deadline's
/// tag beats, and the arrow nudges forward.
class HomePromoStripCard extends StatelessWidget {
  const HomePromoStripCard({
    super.key,
    required this.section,
    required this.onTap,
  });

  final HomePromoStripSection section;
  final VoidCallback onTap;

  /// Strength of the shine on the saturated band.
  static const double _shineAlpha = 0.28;

  @override
  Widget build(BuildContext context) {
    final endsAt = section.endsAt;
    final navigable = section.link.isNavigable;
    return Semantics(
      button: navigable,
      child: GestureDetector(
        onTap: navigable ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: ColoredBox(
          color: HomeAccentPalette.stripFill(section.theme),
          child: LightSweep(
            peakAlpha: _shineAlpha,
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: HomeLayout.gutter,
                vertical: AppSpacing.s16,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (section.badge.isNotEmpty) ...[
                          HomeStripBadge(
                            label: section.badge,
                            fill: AppColors.popupCloseScrim,
                            ink: AppColors.white,
                            beat: endsAt != null,
                          ),
                          const SizedBox(height: AppSpacing.s6),
                        ],
                        Text(
                          section.headline,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.displayMedium.copyWith(
                            color: AppColors.white,
                            fontWeight: AppTextStyles.bold,
                          ),
                        ),
                        if (section.subtitle.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.s4),
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
                          const SizedBox(height: AppSpacing.s8),
                          HomeStripCountdown(
                            endsAt: endsAt,
                            labelColor: AppColors.subtitleOverlay,
                            digitsColor: AppColors.white,
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
        ),
      ),
    );
  }
}
