import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/catalog_circle_add_button.dart';
import '../../../../core/widgets/catalog_pill_stepper.dart';
import '../../../../core/widgets/jameia_image.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/cubit/cart_state.dart';
import '../../domain/entities/recipe_detail.dart';

/// One ingredient: the store product behind it (photo, name, the recipe's
/// note, price) with its cart control. A product that needs a choice or is out
/// of stock opens its page instead. Only THIS tile rebuilds when its quantity
/// changes.
class RecipeIngredientTile extends StatelessWidget {
  const RecipeIngredientTile({
    super.key,
    required this.ingredient,
    required this.pro,
    required this.onOpenProduct,
  });

  final RecipeIngredient ingredient;
  final bool pro;
  final VoidCallback onOpenProduct;

  @override
  Widget build(BuildContext context) {
    final product = ingredient.product;
    return GestureDetector(
      onTap: onOpenProduct,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.s6),
        child: Row(
          children: [
            JameiaImage(
              url: product.image,
              width: AppSize.s56,
              height: AppSize.s56,
              radius: AppSize.r8,
            ),
            const SizedBox(width: AppSpacing.s10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'recipes.ingredient_line'.tr(
                      namedArgs: {
                        'quantity': '${ingredient.purchaseQuantity}',
                        'name': product.name,
                      },
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: AppTextStyles.medium,
                    ),
                  ),
                  if (ingredient.note.isNotEmpty)
                    Text(
                      ingredient.note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.captionLarge.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  Text(
                    product.hasListPrice
                        ? Formatters.price(product.priceKdFor(pro: pro))
                        : 'catalog.choose_options'.tr(),
                    style: AppTextStyles.captionLarge.copyWith(
                      color: product.inStock
                          ? AppColors.primaryText
                          : AppColors.disabledText,
                      fontWeight: AppTextStyles.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            if (!product.inStock)
              Text(
                'catalog.out_of_stock'.tr(),
                style: AppTextStyles.captionLarge.copyWith(
                  color: AppColors.error,
                ),
              )
            else
              BlocSelector<CartCubit, CartState, int>(
                selector: (cart) => cart.qtyOfProduct(product.id),
                builder: (context, qty) {
                  void add() {
                    if (!ingredient.canAddToCart) {
                      onOpenProduct();
                      return;
                    }
                    HapticFeedback.selectionClick();
                    context.read<CartCubit>().addCatalogProduct(product);
                  }

                  return qty <= 0
                      ? CatalogCircleAddButton(
                          label: 'catalog.add_to_cart'.tr(),
                          icon: ingredient.canAddToCart
                              ? Icons.add_rounded
                              : Icons.tune_rounded,
                          onTap: add,
                        )
                      : CatalogPillStepper(
                          qty: qty,
                          onAdd: add,
                          onRemove: () {
                            HapticFeedback.lightImpact();
                            context.read<CartCubit>().removeProduct(product.id);
                          },
                        );
                },
              ),
          ],
        ),
      ),
    );
  }
}
