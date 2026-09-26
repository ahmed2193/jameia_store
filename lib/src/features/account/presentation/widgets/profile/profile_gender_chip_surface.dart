import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';

/// One frame of a gender chip: [tint] (0 = idle grey, 1 = brand fill with a
/// white label) and [round] (0 = soft square corners, 1 = pill) are driven
/// by separate animations in `ProfileGenderChip`. Only paint changes between
/// frames: the fill, the corner radius and the label colour.
class ProfileGenderChipSurface extends StatelessWidget {
  const ProfileGenderChipSurface({
    super.key,
    required this.label,
    required this.tint,
    required this.round,
  });

  static const double height = AppSize.s44;
  static const double _squareRadius = AppRadius.r5;
  static const double _pillRadius = height / 2;

  final String label;
  final double tint;
  final double round;

  @override
  Widget build(BuildContext context) {
    final fill = Color.lerp(AppColors.smallBackground, AppColors.primary, tint);
    final ink = Color.lerp(
      AppColors.primaryText,
      AppColors.brandForeground,
      tint,
    );
    final radius = lerpDouble(_squareRadius, _pillRadius, round) ?? 0;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: fill,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.all(Radius.circular(radius)),
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: height),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s10,
          ),
          child: Align(
            widthFactor: 1,
            heightFactor: 1,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: ink,
                fontWeight: AppTextStyles.medium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
