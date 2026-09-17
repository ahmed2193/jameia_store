import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/widgets/quick_add.dart';
import '../../../store_mode/presentation/cubit/store_mode_cubit.dart';
// TODO(P2.9-boundary): data-layer reverse mapper imported into presentation to
// rebuild the core Product for the cart's quickAddToCart (which consumes the DTO).
import '../../data/mappers/product_mapper.dart';
import '../../domain/entities/featured_section_entity.dart';
import '../../domain/entities/product_entity.dart';
import '../util/featured_section_display.dart';
import '../util/product_display.dart';

/// One home rail for a [FeaturedSection] — a section title + "All" link and a
/// horizontal list of Glovo-style product cards (square image with a floating
/// add control that becomes a − qty + stepper once in the cart, then name ·
/// price · save badge). Prices are VIP/Mart-aware (the list rebuilds on the
/// global `StoreModeCubit` `state.isVip`).
class FeaturedSectionRail extends StatelessWidget {
  const FeaturedSectionRail({
    super.key,
    required this.section,
    required this.onOpenProduct,
    required this.onViewAll,
  });

  final FeaturedSectionEntity section;

  /// Open a product's real shop (caller resolves its category → tab → rank).
  final void Function(ProductEntity product) onOpenProduct;

  /// "View all" — caller opens the section's first product's shop.
  final VoidCallback onViewAll;

  static const double _cardW = 132;
  // Square image + a tight text block (name 2 lines · price · optional save).
  static const double _listH = _cardW + 80;

  @override
  Widget build(BuildContext context) {
    if (section.products.isEmpty) return const SizedBox.shrink();

    return Container(
      color: AppColors.white,
      margin: const EdgeInsets.only(bottom: AppSpacing.s8),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header: title + "All".
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.pageMargin,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    section.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headingMedium.copyWith(
                      fontWeight: AppTextStyles.bold,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onViewAll,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'home.all'.tr(),
                        style: AppTextStyles.captionLarge.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: AppColors.secondaryText,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          // Horizontal product strip (rebuilds on VIP/Mart toggle).
          BlocBuilder<StoreModeCubit, StoreModeState>(
            buildWhen: (a, b) => a.isVip != b.isVip,
            builder: (context, store) {
              final vip = store.isVip;
              return SizedBox(
                height: _listH,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsetsDirectional.only(
                    start: AppSpacing.pageMargin,
                    end: AppSpacing.s4,
                  ),
                  itemCount: section.products.length,
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: false, // we add our own per card below
                  scrollCacheExtent: const ScrollCacheExtent.pixels(600),
                  itemBuilder: (context, i) {
                    final p = section.products[i];
                    return RepaintBoundary(
                      child: _PromoProductCard(
                        product: p,
                        vip: vip,
                        cardW: _cardW,
                        onTap: () => onOpenProduct(p),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Glovo-style promo card: rounded square image with a floating add control
/// overlapping the bottom edge (circular "+" when empty, a "− qty +" pill once
/// in the cart), then name · price · save badge. Dimmed + non-addable when the
/// product is unavailable.
class _PromoProductCard extends StatelessWidget {
  const _PromoProductCard({
    required this.product,
    required this.vip,
    required this.cardW,
    required this.onTap,
  });

  final ProductEntity product;
  final bool vip;
  final double cardW;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final available = product.available;
    final price = product.priceFor(vip);
    final discounted = product.hasDiscount;
    final priceColor = discounted
        ? AppColors.finalPrice
        : AppColors.primaryText;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      // Inter-card gap lives OUTSIDE the width box so the image never overflows.
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: AppSpacing.s8),
        child: SizedBox(
          width: cardW,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: cardW,
                height: cardW,
                child: Stack(
                  children: [
                    Opacity(
                      opacity: available ? 1 : 0.45,
                      child: JameiaImage(
                        url: product.image,
                        width: cardW,
                        height: cardW,
                        radius: AppRadius.card,
                      ),
                    ),
                    if (product.discountPercent > 0)
                      PositionedDirectional(
                        top: AppSpacing.s6,
                        start: AppSpacing.s6,
                        child: _DiscountBadge(percent: product.discountPercent),
                      ),
                    if (!available)
                      const Positioned.fill(child: _UnavailableOverlay()),
                    if (available) _AddControl(product: product, vip: vip),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s6),
              Text(
                product.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primaryText,
                  fontWeight: AppTextStyles.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: AppSpacing.s2),
              Text(
                Formatters.price(price),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: priceColor,
                  fontWeight: AppTextStyles.bold,
                ),
              ),
              if (discounted) ...[
                const SizedBox(height: AppSpacing.s2),
                _SaveBadge(amount: product.originalPrice - price),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Floating add control over the image: circular "+" when the product isn't in
/// the cart, a centered "− qty +" pill once it is. Adds at the VIP-correct price
/// to the unified jameia cart.
class _AddControl extends StatelessWidget {
  const _AddControl({required this.product, required this.vip});
  final ProductEntity product;
  final bool vip;

  void _add(BuildContext context) {
    // TODO(P2.9-boundary): rebuild the core Product for the cart's quickAddToCart,
    // which consumes the core DTO across the feature boundary.
    quickAddToCart(
      context,
      product: product.toModel(),
      unitPrice: product.priceFor(vip),
    );
  }

  void _remove(BuildContext context) {
    HapticFeedback.lightImpact();
    context.read<CartCubit>().removeProduct(product.id);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      buildWhen: (a, b) =>
          a.qtyOfProduct(product.id) != b.qtyOfProduct(product.id),
      builder: (context, cart) {
        final qty = cart.qtyOfProduct(product.id);
        if (qty <= 0) {
          return PositionedDirectional(
            bottom: AppSpacing.s6,
            end: AppSpacing.s6,
            child: _CircleAdd(onTap: () => _add(context)),
          );
        }
        return PositionedDirectional(
          bottom: AppSpacing.s6,
          start: 0,
          end: 0,
          child: Center(
            child: _PillStepper(
              qty: qty,
              onAdd: () => _add(context),
              onRemove: () => _remove(context),
            ),
          ),
        );
      },
    );
  }
}

class _CircleAdd extends StatelessWidget {
  const _CircleAdd({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'home.add_to_cart'.tr(),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.add_rounded,
            size: 20,
            color: AppColors.primaryText,
          ),
        ),
      ),
    );
  }
}

class _PillStepper extends StatelessWidget {
  const _PillStepper({
    required this.qty,
    required this.onAdd,
    required this.onRemove,
  });
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepBtn(
            icon: qty <= 1
                ? Icons.delete_outline_rounded
                : Icons.remove_rounded,
            label: qty <= 1
                ? 'home.remove'.tr()
                : 'home.decrease_quantity'.tr(),
            onTap: onRemove,
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 24),
            alignment: Alignment.center,
            child: Text(
              '$qty',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: AppTextStyles.bold,
              ),
            ),
          ),
          _StepBtn(
            icon: Icons.add_rounded,
            label: 'home.increase_quantity'.tr(),
            onTap: onAdd,
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: AppColors.primaryText),
        ),
      ),
    );
  }
}

/// Top-start gradient discount badge ("N% off" with a flame).
class _DiscountBadge extends StatelessWidget {
  const _DiscountBadge({required this.percent});
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.error, AppColors.accent4],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.r6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department,
            size: 11,
            color: AppColors.white,
          ),
          const SizedBox(width: 2),
          Text(
            'home.percent_off'.tr(namedArgs: {'percent': '$percent'}),
            style: AppTextStyles.captionSmall.copyWith(
              color: AppColors.white,
              fontWeight: AppTextStyles.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Green "Save X" chip shown under the price on a discounted card.
class _SaveBadge extends StatelessWidget {
  const _SaveBadge({required this.amount});
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.successBg,
        borderRadius: BorderRadius.circular(AppRadius.r6),
      ),
      child: Text(
        'home.save_amount'.tr(namedArgs: {'amount': Formatters.price(amount)}),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.captionSmall.copyWith(
          color: AppColors.success,
          fontWeight: AppTextStyles.bold,
        ),
      ),
    );
  }
}

class _UnavailableOverlay extends StatelessWidget {
  const _UnavailableOverlay();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Center(
        child: Text(
          'home.not_available'.tr(),
          style: AppTextStyles.captionMedium.copyWith(
            color: AppColors.secondaryText,
            fontWeight: AppTextStyles.bold,
          ),
        ),
      ),
    );
  }
}
