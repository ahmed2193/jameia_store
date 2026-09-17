import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/models/models.dart';
import '../../../../core/design/jameia_icons.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import 'product_sku_sheet.dart' show kShopSupplierId;

/// Real Jameia sticky cart bar — matches ecf4da / b5ceb4 / a7c4a7 atoms:
///   height 50dp, border-radius 16dp (r3), yellow primary bg when active,
///   #f0f1f5 smallBackground when inactive; Jameia-Bold 16dp center-aligned.
class CartBar extends StatelessWidget {
  const CartBar({super.key, required this.shop});
  final Shop shop;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cart) {
        final active = !cart.isEmpty && cart.shopId == kShopSupplierId;
        return SafeArea(
          top: false,
          child: AnimatedContainer(
            duration: MotionGuard.duration(context, AppMotion.fast),
            // margin 9dp horizontal, 8dp vertical (matches page margin rhythm)
            margin: const EdgeInsetsDirectional.symmetric(
              horizontal: 9,
              vertical: 8,
            ),
            // height 50dp (a19385 / ea707d atoms)
            height: 50,
            decoration: BoxDecoration(
              // active: yellow primary; inactive: #F0F1F5 smallBackground (a7c4a7)
              color: active ? AppColors.primary : AppColors.smallBackground,
              // border-radius 16dp (r3) — both ecf4da and a7c4a7
              borderRadius: BorderRadius.circular(AppRadius.r3),
            ),
            child: active
                ? _ActiveBar(cart: cart, shop: shop)
                : _InactiveBar(shop: shop),
          ),
        );
      },
    );
  }
}

class _ActiveBar extends StatelessWidget {
  const _ActiveBar({required this.cart, required this.shop});
  final CartState cart;
  final Shop shop;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Cart icon + qty badge — padding-left 16dp (d90ad6)
        const SizedBox(width: 16),
        Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              JameiaIcons.cart,
              size: 22,
              color: AppColors.brandForeground,
            ),
            // qty badge: 15dp circle, red #FE4D3D (eb22a2 / b9fe72 atoms)
            PositionedDirectional(
              end: -7,
              top: -7,
              child: Container(
                constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  // FE4D3D — accent red badge (eb22a2: background-color #f0390e)
                  color: AppColors.accent1Dark,
                  borderRadius: BorderRadius.circular(AppSize.r10),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${cart.totalQty}',
                  style: AppTextStyles.captionMedium.copyWith(
                    color: AppColors.white,
                    fontWeight: AppTextStyles.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        // Subtotal price (Jameia-SemiBold 16dp #222222)
        Expanded(
          child: Text(
            Formatters.price(cart.subtotal),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.headingMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.brandForeground,
            ),
          ),
        ),
        // Checkout pill button — inner pill, radius 16dp (e7da4d / b5ceb4)
        GestureDetector(
          onTap: () => context.push(Routes.checkout, extra: shop.id),
          child: Container(
            // min-width 120dp, height fills, padding 0 13dp (e7da4d)
            constraints: const BoxConstraints(minWidth: 120),
            margin: const EdgeInsetsDirectional.only(end: 0),
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              // slightly darker yellow inner pill (c56ab6: brand-primary)
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(AppRadius.r3),
            ),
            alignment: Alignment.center,
            child: Text(
              'shop.checkout'.tr(),
              // e19689 / e332cd: Jameia-Medium 16dp #000000 center
              style: AppTextStyles.headingMedium.copyWith(
                fontWeight: AppTextStyles.bold,
                color: AppColors.brandForeground,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Inactive state: full-width grey pill showing min order.
/// a7c4a7: height 50dp, padding 12dp, border-radius 16dp, #f0f1f5, Jameia-Bold 16dp #222222.
class _InactiveBar extends StatelessWidget {
  const _InactiveBar({required this.shop});
  final Shop shop;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'shop.min_order'.tr(
          namedArgs: {'price': Formatters.price(shop.minOrder)},
        ),
        style: AppTextStyles.headingMedium.copyWith(
          fontWeight: AppTextStyles.bold,
          color: AppColors.primaryText,
        ),
      ),
    );
  }
}
