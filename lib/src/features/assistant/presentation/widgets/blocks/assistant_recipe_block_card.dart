import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_image.dart';
import '../../../domain/entities/assistant_block.dart';
import 'assistant_card_frame.dart';

/// `recipe`: photo, title and "30 min · Serves 4 · 6 ingredients" (the
/// servings the assistant scaled it to); opens the recipe.
class AssistantRecipeBlockCard extends StatelessWidget {
  const AssistantRecipeBlockCard({super.key, required this.block});

  final AssistantRecipeBlock block;

  @override
  Widget build(BuildContext context) {
    final recipe = block.recipe;
    final servings = block.servings > 0 ? block.servings : recipe.servings;
    final meta = [
      if (recipe.totalMinutes > 0)
        'assistant.recipe_minutes'.tr(
          namedArgs: {'minutes': '${recipe.totalMinutes}'},
        ),
      if (servings > 0) 'assistant.recipe_serves'.plural(servings),
      if (block.ingredientCount > 0)
        'assistant.recipe_ingredients'.plural(block.ingredientCount),
    ].join(' · ');
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => context.push(Routes.recipe, extra: recipe.slug),
        child: AssistantCardFrame(
          transparent: true,
          child: Row(
            children: [
              HeroImage(
                url: recipe.imageUrl,
                width: AppSize.s80,
                height: AppSize.s80,
                radius: AppRadius.card,
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headingSmall,
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        meta,
                        style: AppTextStyles.captionLarge.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: AppSize.s22,
                color: AppColors.labelGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
