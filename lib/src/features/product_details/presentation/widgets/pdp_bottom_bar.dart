import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_shadows.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/motion/fly_to_cart.dart';
import '../../../../core/navigation/jameia_snack_bar.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/jameia_card_image.dart';
import '../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../cubit/product_detail_cubit.dart';
import '../cubit/product_detail_state.dart';
import 'pdp_quantity_stepper.dart';

/// Sticky buy bar of the product page: quantity + "Add · total". Disabled with
/// the reason as its label when the selection cannot be bought. Hidden until
/// the product is loaded (the preview has no stock / variant truth yet).
class PdpBottomBar extends StatelessWidget {
  const PdpBottomBar({super.key});

  void _add(BuildContext context, ProductDetailState state) {
    final detail = state.detail;
    if (detail == null || !state.canAdd) return;
    HapticFeedback.selectionClick();
    FlyToCart.flyFrom(
      context,
      thumbnail: JameiaCardImage(
        url: detail.product.image,
        width: AppSize.s56,
        height: AppSize.s56,
        radius: AppRadius.r4,
      ),
    );
    context.read<CartCubit>().addCatalogProduct(
      detail.product,
      variantId: state.selectedVariant?.id,
      quantity: state.quantity,
    );
    showJameiaSnackBar(context, 'product.added_to_cart'.tr());
  }

  @override
  Widget build(BuildContext context) {
    final isPro = context.select<AuthSessionCubit, bool>(
      (session) => session.state.customer?.isPro ?? false,
    );
    return BlocBuilder<ProductDetailCubit, ProductDetailState>(
      buildWhen: (previous, current) =>
          previous.detail != current.detail ||
          previous.quantity != current.quantity ||
          previous.selectedVariantId != current.selectedVariantId,
      builder: (context, state) {
        final detail = state.detail;
        if (detail == null) return const SizedBox.shrink();
        final cubit = context.read<ProductDetailCubit>();
        final totalKd = detail.lineTotalKd(
          variant: state.selectedVariant,
          pro: isPro,
          quantity: state.quantity,
        );
        final label = state.canAdd
            ? 'product.add_with_total'.tr(
                namedArgs: {'total': Formatters.price(totalKd)},
              )
            : detail.needsVariant && state.selectedVariant == null
            ? 'catalog.choose_options'.tr()
            : 'catalog.out_of_stock'.tr();
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.pageMargin,
              AppSpacing.s6,
              AppSpacing.pageMargin,
              AppSpacing.s8,
            ),
            child: Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s10,
                vertical: AppSpacing.s8,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.card),
                boxShadow: AppShadows.high,
              ),
              child: Row(
                children: [
                  if (state.canAdd) ...[
                    PdpQuantityStepper(
                      quantity: state.quantity,
                      onIncrement: cubit.increment,
                      onDecrement: cubit.decrement,
                    ),
                    const SizedBox(width: AppSpacing.s12),
                  ],
                  Expanded(
                    child: AppButton(
                      label: label,
                      enabled: state.canAdd,
                      onPressed: () => _add(context, state),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
