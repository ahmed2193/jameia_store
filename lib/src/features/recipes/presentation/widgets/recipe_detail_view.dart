import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_args/product_detail_args.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/navigation/jameia_snack_bar.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/catalog_recipe_tag.dart';
import '../../../../core/widgets/jameia_image.dart';
import '../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../domain/entities/recipe_detail.dart';
import 'recipe_ingredient_tile.dart';
import 'recipe_section_card.dart';
import 'recipe_step_tile.dart';

/// The loaded recipe: photo header, title / teaser / tags / time, the
/// ingredients as store products (each with its cart control, plus "add all"),
/// then the steps in cooking order.
class RecipeDetailView extends StatelessWidget {
  const RecipeDetailView({super.key, required this.detail});

  final RecipeDetail detail;

  void _addAll(BuildContext context) {
    final cart = context.read<CartCubit>();
    final purchasable = detail.purchasableIngredients;
    HapticFeedback.selectionClick();
    for (final ingredient in purchasable) {
      cart.addCatalogProduct(
        ingredient.product,
        quantity: ingredient.purchaseQuantity,
      );
    }
    showJameiaSnackBar(
      context,
      'recipes.added_all'.tr(namedArgs: {'count': '${purchasable.length}'}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipe = detail.summary;
    final isPro = context.select<AuthSessionCubit, bool>(
      (session) => session.state.customer?.isPro ?? false,
    );
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.white,
          surfaceTintColor: AppColors.white,
          foregroundColor: AppColors.primaryText,
          elevation: 0,
          expandedHeight: AppSize.s240,
          flexibleSpace: FlexibleSpaceBar(
            background: JameiaImage(url: recipe.imageUrl),
          ),
        ),
        SliverList.list(
          children: [
            RecipeSectionCard(
              title: '',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: AppTextStyles.headingLarge.copyWith(
                      fontWeight: AppTextStyles.bold,
                    ),
                  ),
                  if (recipe.excerpt.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s6),
                    Text(
                      recipe.excerpt,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s8),
                  Wrap(
                    spacing: AppSpacing.s6,
                    runSpacing: AppSpacing.s4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (recipe.cuisineName.isNotEmpty)
                        CatalogRecipeTag(label: recipe.cuisineName),
                      if (recipe.dietName.isNotEmpty)
                        CatalogRecipeTag(label: recipe.dietName),
                      Text(
                        'recipes.time_line'.tr(
                          namedArgs: {
                            'prep': '${recipe.prepMinutes}',
                            'cook': '${recipe.cookMinutes}',
                            'servings': '${recipe.servings}',
                          },
                        ),
                        style: AppTextStyles.captionLarge.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (detail.ingredients.isNotEmpty)
              RecipeSectionCard(
                title: 'recipes.ingredients'.tr(),
                child: Column(
                  children: [
                    for (final ingredient in detail.ingredients)
                      RecipeIngredientTile(
                        key: ValueKey(ingredient.id),
                        ingredient: ingredient,
                        pro: isPro,
                        onOpenProduct: () => context.push(
                          Routes.productDetail,
                          extra: ProductDetailArgs.of(ingredient.product),
                        ),
                      ),
                    if (detail.purchasableIngredients.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s8),
                      AppButton(
                        label: 'recipes.add_all'.tr(),
                        onPressed: () => _addAll(context),
                      ),
                    ],
                  ],
                ),
              ),
            if (detail.steps.isNotEmpty)
              RecipeSectionCard(
                title: 'recipes.steps'.tr(),
                child: Column(
                  children: [
                    for (final step in detail.steps)
                      RecipeStepTile(key: ValueKey(step.id), step: step),
                  ],
                ),
              ),
            const SizedBox(height: AppSize.s24),
          ],
        ),
      ],
    );
  }
}
