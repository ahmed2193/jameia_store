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
import '../../../../core/widgets/hero_card_image.dart';
import '../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/cubit/cart_state.dart';
import '../cubit/product_detail_cubit.dart';
import '../cubit/product_detail_state.dart';
import 'pdp_bar_price_block.dart';
import 'pdp_cart_cta.dart';

/// Sticky buy bar of the product page, white on a soft top shadow: the
/// price block at the start — the deal's "Save N%", the price (the line
/// total once the selection is in the cart), the struck price and the Pro
/// line — and the big green "Add to cart" block at the end, which turns into
/// a stepper of that cart line. Adding flies the product from the gallery
/// ([galleryKey]) into the cart. Disabled with the reason as its label when
/// the selection cannot be bought. Hidden until the product is loaded (the
/// preview has no stock / variant truth yet).
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
    final thumbnail = HeroCardImage(
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
          previous.selectedVariantId != current.selectedVariantId,
      builder: (context, state) {
        final detail = state.detail;
        if (detail == null) return const SizedBox.shrink();
        final variant = state.selectedVariant;
        final ref = CartLineRef(detail.product.id, variant?.id);
        final stock = detail.stockOf(variant);
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
                  final quote = detail.quoteFor(
                    variant: variant,
                    pro: isPro,
                    now: DateTime.now(),
                    quantity: quantity < 1 ? 1 : quantity,
                  );
                  final cart = context.read<CartCubit>();
                  return Row(
                    children: [
                      Expanded(
                        child: quote.hasPrice
                            ? PdpBarPriceBlock(
                                quote: quote,
                                option: (variant?.id, quote.unitFils),
                              )
                            : const SizedBox.shrink(),
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
