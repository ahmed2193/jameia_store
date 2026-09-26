import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_shadows.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/domain/entities/cart_line_entity.dart';
import '../../../../core/domain/entities/cart_line_ref.dart';
import '../../../../core/motion/fly_to_cart.dart';
import '../../../../core/motion/haptics.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/jameia_card_image.dart';
import '../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/cubit/cart_state.dart';
import '../cubit/product_detail_cubit.dart';
import '../cubit/product_detail_state.dart';
import 'pdp_bar_price.dart';
import 'pdp_cart_cta.dart';
import 'pdp_promo_tag.dart';

/// Sticky buy bar of the product page, white on a soft top shadow: the
/// price at the start (the line total once the selection is in the cart)
/// under the red tag of the cart offer that counts the product, when one
/// does, and the big green "Add to cart" block at the end, which turns into a stepper of
/// that cart line. Adding flies the product from the gallery ([galleryKey])
/// into the cart. Disabled with the reason as its label when the selection
/// cannot be bought. Hidden until the product is loaded (the preview has no
/// stock / variant truth yet).
class PdpBottomBar extends StatelessWidget {
  const PdpBottomBar({super.key, this.galleryKey});

  /// The gallery the flight takes off from; the bar itself when the gallery
  /// is scrolled out of sight (or unknown).
  final GlobalKey? galleryKey;

  static const double _thumb = AppSize.s56;

  void _add(BuildContext context, ProductDetailState state) {
    final detail = state.detail;
    if (detail == null || !state.canAdd) return;
    Haptics.tap();
    final thumbnail = JameiaCardImage(
      url: detail.product.image,
      width: _thumb,
      height: _thumb,
      radius: AppRadius.r4,
    );
    final gallery = galleryKey;
    if (gallery != null && _isOnScreen(gallery)) {
      FlyToCart.fly(context, sourceKey: gallery, thumbnail: thumbnail);
    } else {
      FlyToCart.flyFrom(context, thumbnail: thumbnail);
    }
    context.read<CartCubit>().addCatalogProduct(
      detail.product,
      variantId: state.selectedVariant?.id,
    );
  }

  /// Whether some of [key]'s box still shows. The gallery is the first
  /// thing on the page, so it only ever leaves through the top.
  static bool _isOnScreen(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return false;
    return box.localToGlobal(box.size.bottomLeft(Offset.zero)).dy > 0;
  }

  @override
  Widget build(BuildContext context) {
    final isPro = context.select<AuthSessionCubit, bool>(
      (session) => session.state.customer?.isPro ?? false,
    );
    return BlocBuilder<ProductDetailCubit, ProductDetailState>(
      buildWhen: (previous, current) =>
          previous.detail != current.detail ||
          previous.selectedVariantId != current.selectedVariantId ||
          previous.promo != current.promo,
      builder: (context, state) {
        final detail = state.detail;
        if (detail == null) return const SizedBox.shrink();
        final variant = state.selectedVariant;
        final ref = CartLineRef(detail.product.id, variant?.id);
        final unitFils = detail.unitPriceFils(variant: variant, pro: isPro);
        final stock = detail.stockOf(variant);
        final promo = state.promo;
        final disabledLabel = detail.needsVariant && variant == null
            ? 'catalog.choose_options'.tr()
            : 'catalog.out_of_stock'.tr();
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.white,
            boxShadow: AppShadows.barTop,
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s16,
                vertical: AppSpacing.s12,
              ),
              // Only the bar's contents follow the cart, never the page.
              child: BlocSelector<CartCubit, CartState, CartLineEntity?>(
                selector: (cart) => cart.cart.lineFor(ref),
                builder: (context, line) {
                  final quantity = line?.quantity ?? 0;
                  // Per piece until the selection is in the cart, then the
                  // line total.
                  final pieces = quantity < 1 ? 1 : quantity;
                  final now = DateTime.now();
                  final cart = context.read<CartCubit>();
                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (promo != null) ...[
                              PdpPromoTag(label: promo.name),
                              const SizedBox(height: AppSpacing.s6),
                            ],
                            if (unitFils > 0)
                              PdpBarPrice(
                                amountKd: detail.lineTotalKd(
                                  variant: variant,
                                  pro: isPro,
                                  quantity: pieces,
                                ),
                                struckKd: detail.struckTotalKd(
                                  variant: variant,
                                  pro: isPro,
                                  now: now,
                                  quantity: pieces,
                                ),
                                deal:
                                    detail.compareAtFils(
                                      variant: variant,
                                      now: now,
                                    ) !=
                                    null,
                                option: (variant?.id, unitFils),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: PdpCartCta(
                          enabled: state.canAdd,
                          disabledLabel: disabledLabel,
                          quantity: quantity,
                          canIncrement:
                              quantity < stock && (line?.canIncrement ?? true),
                          onAdd: () => _add(context, state),
                          onIncrement: () {
                            if (line != null) cart.increment(line);
                          },
                          onDecrement: () {
                            if (line != null) cart.decrement(line);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
