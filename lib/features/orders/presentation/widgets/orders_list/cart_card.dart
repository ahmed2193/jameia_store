import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/keeta_icons.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/routing/routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../../cart/presentation/screens/cart_preview_screen.dart';
import 'cart_items_preview.dart';
import 'order_pill_button.dart';

/// Single-store "Your cart" card. Mirrors the [OrderCard] shell (white 12dp
/// card, 40dp header glyph, divider, item summary, count/subtotal footer) but
/// reads the live cart and opens the dedicated [CartPreviewScreen]. Single store
/// → one card, not a per-shop list.
class CartCard extends StatelessWidget {
  const CartCard({super.key, required this.cart});

  final CartState cart;

  void _openCart(BuildContext context) => Navigator.of(context).push(
    KeetaPageRoute<void>(
      page: const CartPreviewScreen(),
      settings: const RouteSettings(name: Routes.cartPreview),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.s12),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: () => _openCart(context),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.s10,
              AppSpacing.s16,
              AppSpacing.s10,
              AppSpacing.s20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: cart glyph + "Your cart"
                Row(
                  children: [
                    Container(
                      width: AppSpacing.s40,
                      height: AppSpacing.s40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.smallBackground,
                        borderRadius: BorderRadius.circular(AppRadius.r4),
                      ),
                      child: const Icon(
                        KeetaIcons.cart,
                        size: 20,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Expanded(
                      child: Text(
                        'orders.your_cart'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.headingMedium.copyWith(
                          fontWeight: AppTextStyles.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s10),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.overlayDivider,
                ),
                const SizedBox(height: AppSpacing.s8),
                CartItemsPreview(lines: cart.lines),
                const SizedBox(height: AppSpacing.s8),
                // Footer: item count + subtotal
                Row(
                  children: [
                    Text(
                      'orders.item_count'.tr(
                        namedArgs: {'count': '${cart.totalQty}'},
                      ),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.tertiaryText,
                        fontWeight: AppTextStyles.regular,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      Formatters.price(cart.subtotal),
                      style: AppTextStyles.headingSmall.copyWith(
                        fontWeight: AppTextStyles.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s12),
                // View-cart CTA (mirrors the completed-order pill actions).
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: OrderPillButton(
                    label: 'orders.view_cart'.tr(),
                    icon: KeetaIcons.cart,
                    filled: true,
                    onPressed: () => _openCart(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
