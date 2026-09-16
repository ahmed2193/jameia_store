import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design/keeta_assets.dart';
import '../../../../../core/design/keeta_icons.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/core_widgets.dart';
// TODO(P2.9-boundary): CartCubit/CartState (and its List<CartItem> lines) are
// the cart feature's — read here and passed straight into placeOrder; kept as
// the core types at this cross-feature boundary.
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../domain/entities/checkout_draft.dart';
import '../../../domain/entities/shop_entity.dart';
import '../../cubit/checkout_cubit.dart';
import '../../util/shop_display.dart';

/// Sticky bottom bar — full-width yellow pill CTA.
/// Real KeeTa metrics: h:50dp, border-radius:25dp (pill), bg:#FFE41F,
/// font-size:16dp, font-weight:700. Bottom padding 34dp (safe area zone).
/// Left side shows total + "Incl. fees" label.
class PlaceOrderBar extends StatelessWidget {
  const PlaceOrderBar({super.key, required this.shop, required this.draft});
  final ShopEntity shop;
  final CheckoutDraft draft;

  /// KeeTa shows a secondary-confirm dialog (`ic_secondary_confirm_icon`) before
  /// committing the order: review total + payment, then Cancel / Confirm.
  void _placeOrder(BuildContext context) {
    final cart = context.read<CartCubit>();
    final checkout = context.read<CheckoutCubit>();
    final total = draft.totalFor(cart.state.subtotal, shop.effectiveDeliveryFee);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              KeetaAssets.secondaryConfirmIcon,
              width: 48,
              height: 48,
              errorBuilder: (context, error, stackTrace) => const Icon(
                KeetaIcons.orders,
                color: AppColors.primaryText,
                size: 44,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'checkout.confirm_title'.tr(),
              style: AppTextStyles.headingLarge.copyWith(
                fontWeight: AppTextStyles.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'checkout.total'.tr(),
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                const Spacer(),
                PriceText(price: total, size: 16),
              ],
            ),
            const SizedBox(height: AppSpacing.s4),
            Row(
              children: [
                Text(
                  'checkout.deliver_to'.tr(),
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                const Spacer(),
                Text(
                  shop.displayName,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: AppTextStyles.medium,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: AppOutlineButton(
                  label: 'checkout.cancel'.tr(),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: AppButton(
                  label: 'checkout.confirm'.tr(),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    // Commit through the cubit; the screen's placed-listener
                    // clears the cart and shows the success dialog.
                    checkout.placeOrder(
                      shop: shop,
                      lines: cart.state.lines,
                      subtotal: cart.state.subtotal,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cart) {
        if (cart.isEmpty) return const SizedBox.shrink();
        final total = draft.totalFor(cart.subtotal, shop.effectiveDeliveryFee);
        // Bottom padding: 16dp top + 34dp bottom (css g979b4: padding:16dp 16dp 34dp 16dp)
        final bottomInset = MediaQuery.paddingOf(context).bottom;
        return Container(
          color: AppColors.white,
          padding: EdgeInsetsDirectional.fromSTEB(
            AppSpacing.s16,
            AppSpacing.s12,
            AppSpacing.s16,
            AppSpacing.s12 + (bottomInset > 0 ? bottomInset : AppSpacing.s4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Price line above CTA button
              Row(
                children: [
                  PriceText(price: total, size: 20, animate: true),
                  const SizedBox(width: AppSpacing.s4),
                  Text(
                    '· ${'checkout.incl_fees'.tr()}',
                    style: AppTextStyles.captionLarge.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s10),
              // Full-width yellow pill button (ha4a54: h:50dp r:25dp bg:#FFE41F)
              GestureDetector(
                onTap: () => _placeOrder(context),
                child: Container(
                  width: double.infinity,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppSize.r25), // pill = 25dp
                  ),
                  child: Text(
                    'checkout.place_order'.tr(),
                    style: AppTextStyles.headingMedium.copyWith(
                      fontWeight: AppTextStyles.bold,
                      color: AppColors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
