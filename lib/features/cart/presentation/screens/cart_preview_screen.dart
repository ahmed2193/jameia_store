import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// TODO(P2.9-boundary): `_CartLineRow` renders the core `CartItem` carried by
// `cart.lines` (the same DTO the checkout / orders features consume), so this
// screen deliberately keeps the shared `core/data/models` type rather than a
// framework-free entity. The B2 checkout-shop resolution no longer reads
// `core/data/keeta_repository.dart` — it routes through `CartCubit`.
import '../../../../core/data/models/models.dart';
import '../../../../core/design/keeta_icons.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/cart_cubit.dart';

/// Dedicated single-store cart screen (opened from the Orders "In progress"
/// tab's cart card). Reads the app-root [CartCubit] — the same unified basket
/// the whole Jameia store shares — lists its lines with editable [QtyStepper]s,
/// and hands off to the `order_confirm_global` checkout to actually place the
/// order (Cart → Checkout → place order).
///
/// Not wired through [AppRouter] — the routing dir is edit-protected and
/// `Routes.cartPreview` has no case — so callers push it with the app's own
/// [KeetaPageRoute] transition. The route still carries `Routes.cartPreview` as
/// its `settings.name` for consistency.
class CartPreviewScreen extends StatelessWidget {
  const CartPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mediumBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'cart.title'.tr(),
          style: AppTextStyles.displaySmall.copyWith(
            fontWeight: AppTextStyles.medium,
          ),
        ),
      ),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, cart) {
          if (cart.isEmpty) {
            return EmptyStateView(
              message: 'cart.empty'.tr(),
              icon: KeetaIcons.cart,
              actionLabel: 'checkout.add_more_items'.tr(),
              onAction: () => Navigator.of(context).maybePop(),
            );
          }
          final lines = cart.lines;
          return ContentClamp(
            child: Column(
              children: [
                Expanded(
                  child: ColoredBox(
                    color: AppColors.white,
                    child: ListView.separated(
                      padding: const EdgeInsetsDirectional.only(
                        top: AppSpacing.s4,
                        bottom: AppSpacing.s16,
                      ),
                      itemCount: lines.length,
                      separatorBuilder: (_, _) =>
                          const ThinDivider(indent: AppSpacing.s16),
                      itemBuilder: (_, i) => _CartLineRow(line: lines[i]),
                    ),
                  ),
                ),
                _CartBottomBar(cart: cart),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// One editable cart line: image, name + unit price, and a [QtyStepper] wired to
/// the app-root cart (mirrors the shop product row's add/remove wiring).
class _CartLineRow extends StatelessWidget {
  const _CartLineRow({required this.line});

  final CartItem line;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CartCubit>();
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s16,
        AppSpacing.s12,
        AppSpacing.s16,
        AppSpacing.s12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          KeetaCardImage(
            url: line.displayImage,
            width: AppSpacing.s(56),
            height: AppSpacing.s(56),
            radius: AppRadius.r4,
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  line.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                PriceText(price: line.unitPrice, size: 14),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          QtyStepper(
            qty: line.qty,
            onAdd: () => cubit.add(
              line.product,
              line.shopId,
              variant: line.variant,
              unitPrice: line.unitPriceOverride,
            ),
            onRemove: () => cubit.remove(line.lineKey),
          ),
        ],
      ),
    );
  }
}

/// Sticky footer: subtotal + a full-width Checkout CTA. Checkout is resolved to
/// a real, router-resolvable shop id (the unified cart's `shopId` is the
/// synthetic `jameia`, which `shopById` doesn't carry — fall back to the first
/// catalogue shop, the same idiom the Orders reorder path uses).
class _CartBottomBar extends StatelessWidget {
  const _CartBottomBar({required this.cart});

  final CartState cart;

  void _checkout(BuildContext context) {
    // B2 — the unified cart's `shopId` is the synthetic `jameia` (not router-
    // resolvable), so the cubit resolves it to a real catalogue shop id via the
    // repository. Keeps this screen off `core/data/keeta_repository.dart`.
    final shopId = context.read<CartCubit>().resolveCheckoutShopId();
    if (shopId == null) return;
    Navigator.pushNamed(context, Routes.checkout, arguments: shopId);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      elevation: 8,
      shadowColor: AppColors.divider,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.s16,
            AppSpacing.s12,
            AppSpacing.s16,
            AppSpacing.s12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'checkout.subtotal'.tr(),
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const Spacer(),
                  PriceText(price: cart.subtotal, size: 18, animate: true),
                ],
              ),
              const SizedBox(height: AppSpacing.s12),
              AppButton(
                label: 'shop.checkout'.tr(),
                radius: AppRadius.r2,
                onPressed: () => _checkout(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
