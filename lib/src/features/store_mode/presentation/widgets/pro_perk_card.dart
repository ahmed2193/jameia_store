import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_shadows.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import 'pro_underlined_link.dart';

/// One Pro perk as a softly tinted card (its [color] fading lighter towards
/// the bottom-end corner, a low shadow): title, body, an optional link, and
/// a big icon disc with a soft violet halo hanging off the card's bottom-end
/// corner. [active]: a member's perk — a green "On" pill at the top-end
/// corner says it already applies.
class ProPerkCard extends StatelessWidget {
  const ProPerkCard({
    super.key,
    required this.color,
    required this.icon,
    required this.title,
    required this.body,
    this.ctaLabel,
    this.onCta,
    this.active = false,
  });

  static const double _disc = AppSize.s120;
  static const double _halo = AppSize.s180;

  /// Centres the halo on the disc.
  static const double _haloInset = -_overhang - (_halo - _disc) / 2;

  /// How much of the disc hangs outside the card (clipped).
  static const double _overhang = AppSize.s30;

  /// Keeps the copy clear of the disc.
  static const double _copyEndGap = AppSize.s96;
  static const double _iconSize = AppSize.s48;

  /// How far the tint fades towards white at the bottom-end corner.
  static const double _tintFade = 0.6;
  static const double _haloAlpha = 0.18;

  /// Pulls the icon towards the disc's visible (top-start) part.
  static const AlignmentDirectional _iconAlignment = AlignmentDirectional(
    -0.3,
    -0.3,
  );

  final Color color;
  final IconData icon;
  final String title;
  final String body;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final bool active;

  static const double _check = AppSize.s14;

  @override
  Widget build(BuildContext context) {
    final cta = ctaLabel;
    final onTap = onCta;
    // Each perk reads as its own group; its link stays a separate node.
    return Semantics(
      container: true,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [color, Color.lerp(color, AppColors.white, _tintFade)!],
          ),
          borderRadius: BorderRadius.circular(AppRadius.r2),
          boxShadow: AppShadows.low,
        ),
        child: Stack(
          children: [
            PositionedDirectional(
              end: _haloInset,
              bottom: _haloInset,
              child: SizedBox.square(
                dimension: _halo,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.accentViolet.withValues(alpha: _haloAlpha),
                        AppColors.accentViolet.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              end: -_overhang,
              bottom: -_overhang,
              child: Container(
                width: _disc,
                height: _disc,
                alignment: _iconAlignment,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryText,
                    width: AppSize.s3,
                  ),
                ),
                child: Icon(
                  icon,
                  size: _iconSize,
                  color: AppColors.accentViolet,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.s20,
                AppSpacing.s20,
                _copyEndGap,
                AppSpacing.s20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.headingLarge.copyWith(
                      fontSize: AppSize.font20,
                      fontWeight: AppTextStyles.bold,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s6),
                  Text(
                    body,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                  if (cta != null && onTap != null) ...[
                    const SizedBox(height: AppSpacing.s4),
                    ProUnderlinedLink(label: cta, onTap: onTap),
                  ],
                ],
              ),
            ),
            if (active)
              PositionedDirectional(
                top: AppSpacing.s12,
                end: AppSpacing.s12,
                child: PopScale.onMount(
                  child: Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.s8,
                      vertical: AppSpacing.s2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successBg,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppColors.success),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_rounded,
                          size: _check,
                          color: AppColors.brandDeep,
                        ),
                        const SizedBox(width: AppSpacing.s2),
                        Text(
                          'pro.perk_on'.tr(),
                          style: AppTextStyles.captionMedium.copyWith(
                            fontWeight: AppTextStyles.bold,
                            color: AppColors.brandDeep,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
