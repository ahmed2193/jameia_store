import 'package:flutter/material.dart';

import '../../../../../../config/theme/app_colors.dart';
import '../../../../../../config/theme/app_shadows.dart';
import '../../../../../../config/theme/app_spacing.dart';
import '../../../../../../config/theme/app_text_styles.dart';
import '../../../../../../core/responsive/app_size.dart';

/// A note beside the ready demo's phone with an arrow at what it names —
/// towards the end edge ([pointsToEnd]) or back towards the start. Pops in
/// from the arrow's side with [appear].
class AssistantOnboardingHintChip extends StatelessWidget {
  const AssistantOnboardingHintChip({
    super.key,
    required this.text,
    required this.appear,
    required this.pointsToEnd,
  });

  final String text;
  final double appear;
  final bool pointsToEnd;

  static const double _maxWidth = AppSize.s92;
  static const BoxDecoration _pill = BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
    boxShadow: AppShadows.low,
  );

  @override
  Widget build(BuildContext context) {
    // Material's forward / back arrows turn with the reading direction.
    final arrow = Icon(
      pointsToEnd ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
      size: AppSize.s12,
      color: AppColors.primaryDark,
    );
    return Transform.scale(
      scale: appear,
      alignment: pointsToEnd
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: DecoratedBox(
          decoration: _pill,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s8,
              vertical: AppSpacing.s5,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!pointsToEnd) ...[
                  arrow,
                  const SizedBox(width: AppSpacing.s4),
                ],
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      text,
                      maxLines: 1,
                      style: AppTextStyles.captionMedium.copyWith(
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                ),
                if (pointsToEnd) ...[
                  const SizedBox(width: AppSpacing.s4),
                  arrow,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
