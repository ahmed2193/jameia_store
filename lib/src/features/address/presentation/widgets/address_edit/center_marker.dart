import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';

/// Fixed map-centre marker: the drawn Hero pin ([HeroAssets.mapPin], green
/// in an ink outline) over a soft ground shadow, with an optional white label
/// bubble. Lifts a few px while panning; the shadow widens as it lifts.
/// Decorative: the label bubble and the sheet say where it points.
class CenterMarker extends StatelessWidget {
  const CenterMarker({super.key, required this.raised, required this.label});
  final bool raised;
  final String label;

  /// Space under the pin so its tip and shadow sit on the map's geometric
  /// centre (the label bubble + pin head stack above it). Same tip-to-centre
  /// offset as the painted pin it replaced: the drawing is 6 dp taller above
  /// the tip, so the space below grows by 6 too.
  static const double _pinClearance = 53;
  static const double _pinWidth = AppSize.s40;
  static const double _pinHeight = AppSize.s48;

  /// The drawing ends this far under the pin's tip; the shadow tucks up by
  /// it so it touches the tip.
  static const double _tipInset = AppSize.s4;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: MotionGuard.duration(context, AppMotion.fast),
      curve: MotionGuard.curve(context, AppMotion.signature),
      offset: Offset(0, raised ? -0.08 : 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxWidth: AppSize.s240),
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s12,
                vertical: AppSpacing.s8,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.overlayDivider,
                    blurRadius: AppSize.s8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.captionLarge.copyWith(
                  color: AppColors.primaryText,
                  fontWeight: AppTextStyles.medium,
                ),
              ),
            ),
          if (label.isNotEmpty) const SizedBox(height: AppSpacing.s6),

          SvgPicture.asset(
            HeroAssets.mapPin,
            width: _pinWidth,
            height: _pinHeight,
            excludeFromSemantics: true,
          ),
          // Ground shadow, under the tip.
          Transform.translate(
            offset: const Offset(0, -_tipInset),
            child: AnimatedContainer(
              duration: MotionGuard.duration(context, AppMotion.fast),
              curve: MotionGuard.curve(context, AppMotion.signature),
              width: raised ? 12 : 9,
              height: raised ? 5 : 4,
              decoration: BoxDecoration(
                color: AppColors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          // Spacer so the tip/shadow sit on the geometric centre.
          const SizedBox(height: _pinClearance),
        ],
      ),
    );
  }
}
