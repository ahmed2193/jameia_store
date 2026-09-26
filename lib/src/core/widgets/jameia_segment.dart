import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../motion/motion.dart';

/// One label of a [JameiaSegmentedControl]: see-through, so the control's
/// sliding thumb shows beneath it; its label colour cross-fades to white when
/// the thumb sits under it.
class JameiaSegment extends StatelessWidget {
  const JameiaSegment({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;

  /// `null` = disabled.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Center(
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s8,
            ),
            child: AnimatedDefaultTextStyle(
              duration: MotionGuard.duration(context, AppMotion.fast),
              curve: AppMotion.signature,
              style: AppTextStyles.headingSmall.copyWith(
                fontWeight: AppTextStyles.bold,
                color: selected ? AppColors.white : AppColors.primaryText,
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ),
      ),
    );
  }
}
