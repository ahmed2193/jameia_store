import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/responsive/app_size.dart';
import '../../domain/entities/recipe_detail.dart';

/// One cooking step: its number on a disc, the instruction and, when the
/// backend gave one, how long it takes.
class RecipeStepTile extends StatelessWidget {
  const RecipeStepTile({super.key, required this.step});

  final RecipeStep step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppSize.s28,
            height: AppSize.s28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.brandLightBg,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${step.order}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primaryDark,
                fontWeight: AppTextStyles.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.body, style: AppTextStyles.bodyLarge),
                if (step.durationMinutes > 0) ...[
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    'recipes.step_minutes'.tr(
                      namedArgs: {'minutes': '${step.durationMinutes}'},
                    ),
                    style: AppTextStyles.captionLarge.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
