import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/motion/fly_to_cart.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../cubit/product_detail_cubit.dart';

/// Sticky product-detail action bar: a "{n}% off" badge over the (animated)
/// price with its struck original, and a green "Add to cart" CTA that adds the
/// chosen variant × quantity to the unified cart and arcs the product image into
/// the cart badge.
class PdpBottomBar extends StatelessWidget {
  const PdpBottomBar({super.key});

  void _add(BuildContext context, ProductDetailState state) {
    context.read<ProductDetailCubit>().addToCart(context.read<CartCubit>());
    FlyToCart.flyFrom(
      context,
      thumbnail: JameiaCardImage(
        url: state.heroImage,
        width: 56,
        height: 56,
        radius: AppRadius.r4,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductDetailCubit, ProductDetailState>(
      builder: (context, state) {
        if (state.status != ProductDetailStatus.loaded) {
          return const SizedBox.shrink();
        }
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(
              top: BorderSide(color: AppColors.divider, width: 0.5),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.s16,
                AppSpacing.s10,
                AppSpacing.s16,
                AppSpacing.s10,
              ),
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (state.discountPercent > 0) ...[
                        _OffBadge(percent: state.discountPercent),
                        const SizedBox(height: AppSpacing.s2),
                      ],
                      PriceText(
                        price: state.unitPrice,
                        originalPrice: state.oldPrice,
                        size: 20,
                        animate: true,
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.s16),
                  Expanded(
                    child: AppButton(
                      label: state.canAdd
                          ? 'product.add_to_cart'.tr()
                          : 'shop.out_of_stock'.tr(),
                      onPressed: state.canAdd
                          ? () => _add(context, state)
                          : null,
                      color: AppColors.martGreen,
                      foreground: AppColors.white,
                      height: 48,
                      radius: AppRadius.r1,
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

/// Small red "{n}% off" badge shown above the sticky price.
class _OffBadge extends StatelessWidget {
  const _OffBadge({required this.percent});
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 5,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: AppColors.finalPrice,
        borderRadius: BorderRadius.circular(AppRadius.r7),
      ),
      child: Text(
        'home.percent_off'.tr(namedArgs: {'percent': '$percent'}),
        style: AppTextStyles.captionSmall.copyWith(
          color: AppColors.white,
          fontWeight: AppTextStyles.bold,
        ),
      ),
    );
  }
}
