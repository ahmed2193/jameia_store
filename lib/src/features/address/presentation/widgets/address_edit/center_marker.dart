import 'package:flutter/material.dart';

import '../../../../../core/motion/motion.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';

/// Fixed map-centre marker: a black teardrop pin (filled head + inner white dot)
/// with an optional white label bubble. Lifts a few px while panning.
class CenterMarker extends StatelessWidget {
  const CenterMarker({super.key, required this.raised, required this.label});
  final bool raised;
  final String label;

  /// Space under the pin so its tip and shadow sit on the map's geometric
  /// centre (the label bubble + pin head stack above it).
  static const double _pinClearance = 51;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: MotionGuard.duration(context, AppMotion.fast),
      curve: MotionGuard.curve(context, AppMotion.standard),
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

          // Black teardrop pin head (circle + inner white dot).
          Container(
            width: AppSize.s26,
            height: AppSize.s26,
            decoration: const BoxDecoration(
              color: AppColors.black,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Container(
              width: AppSize.s9,
              height: AppSize.s9,
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Short stem + ground shadow.
          Container(
            width: AppSize.s2,
            height: AppSize.s12,
            color: AppColors.black,
          ),
          AnimatedContainer(
            duration: MotionGuard.duration(context, AppMotion.fast),
            curve: MotionGuard.curve(context, AppMotion.standard),
            width: raised ? 12 : 9,
            height: raised ? 5 : 4,
            decoration: BoxDecoration(
              color: AppColors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          // Spacer so the tip/shadow sit on the geometric centre.
          const SizedBox(height: _pinClearance),
        ],
      ),
    );
  }
}
