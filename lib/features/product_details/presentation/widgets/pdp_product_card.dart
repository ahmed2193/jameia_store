import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/data/catalog_constants.dart' show kJameiaSupplierId;
import '../../../../core/data/models/models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/widgets/quick_add.dart';
import '../../../shop/presentation/widgets/product_sku_sheet.dart';

/// KeeMart product-detail grid card ("Similar Products" / "Explore More").
///
/// Matches the live KeeMart card order: square image with an orange discount
/// ribbon and a GREEN floating "+" add control, then the price (+ struck
/// original), a single promo chip, the name (2 lines) and the pack weight.
class PdpProductCard extends StatelessWidget {
  const PdpProductCard({
    super.key,
    required this.product,
    required this.vip,
    required this.width,
    required this.onTap,
  });

  final Product product;
  final bool vip;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final available = product.available;
    final price = product.priceFor(vip);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: width,
              height: width,
              child: Stack(
                children: [
                  Opacity(
                    opacity: available ? 1 : 0.45,
                    child: KeetaImage(
                      url: product.image,
                      width: width,
                      height: width,
                      radius: AppRadius.card,
                    ),
                  ),
                  if (product.discountPercent > 0)
                    PositionedDirectional(
                      top: 0,
                      start: 0,
                      child: _DiscountRibbon(percent: product.discountPercent),
                    ),
                  if (!available)
                    const Positioned.fill(child: _UnavailableOverlay()),
                  if (available) _AddControl(product: product, vip: vip),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            PriceText(
              price: price,
              originalPrice: product.hasDiscount ? product.originalPrice : 0,
              size: 15,
            ),
            if (_chipLabel != null) ...[
              const SizedBox(height: AppSpacing.s6),
              _CardChip(label: _chipLabel!, chevron: _chipChevron),
            ],
            const SizedBox(height: AppSpacing.s6),
            Text(
              product.displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primaryText,
                height: 1.25,
              ),
            ),
            if (product.weight.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s2),
              Text(
                product.weight,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.captionLarge
                    .copyWith(color: AppColors.tertiaryText),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? get _chipLabel {
    if (product.hasVariants) {
      return 'product.options_count'
          .tr(namedArgs: {'count': '${product.variants.length}'});
    }
    if (product.firstUnitsQty > 0 && product.hasPromo) {
      return 'product.first_order_deal'.tr();
    }
    if (product.showDiscount || product.hasDiscount) {
      return 'product.extra_discount'.tr();
    }
    return null;
  }

  bool get _chipChevron =>
      !product.hasVariants && product.firstUnitsQty > 0 && product.hasPromo;
}

/// A peach-tinted promo chip under the price ("First-order deal ›" / "Extra
/// discount" / "2 options").
class _CardChip extends StatelessWidget {
  const _CardChip({required this.label, this.chevron = false});
  final String label;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsetsDirectional.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: kJameiaPromoPink,
        borderRadius: BorderRadius.circular(AppRadius.r6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.captionSmall.copyWith(
                color: AppColors.accent1,
                fontWeight: AppTextStyles.medium,
              ),
            ),
          ),
          if (chevron)
            const Icon(Icons.chevron_right, size: 12, color: AppColors.accent1),
        ],
      ),
    );
  }
}

/// Orange cut-corner discount ribbon anchored to the image's top-start.
class _DiscountRibbon extends StatelessWidget {
  const _DiscountRibbon({required this.percent});
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsetsDirectional.symmetric(horizontal: 7, vertical: 3),
      decoration: const BoxDecoration(
        color: AppColors.accent1,
        borderRadius: BorderRadiusDirectional.only(
          topStart: Radius.circular(AppRadius.card),
          bottomEnd: Radius.circular(AppRadius.card),
        ),
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

/// Floating GREEN add control over the image — circular "+" when the product
/// isn't in the cart, a "− qty +" pill once it is. Variant products open the SKU
/// sheet instead of quick-adding.
class _AddControl extends StatelessWidget {
  const _AddControl({required this.product, required this.vip});
  final Product product;
  final bool vip;

  void _add(BuildContext context) {
    if (product.hasVariants) {
      showProductSku(context, product: product, shopId: kJameiaSupplierId);
    } else {
      quickAddToCart(context, product: product, unitPrice: product.priceFor(vip));
    }
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
            color: AppColors.martGreen,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, size: 20, color: AppColors.white),
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
            icon: qty <= 1 ? Icons.delete_outline_rounded : Icons.remove_rounded,
            label: qty <= 1 ? 'home.remove'.tr() : 'home.decrease_quantity'.tr(),
            onTap: onRemove,
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 24),
            alignment: Alignment.center,
            child: Text('$qty',
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: AppTextStyles.bold)),
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
  const _StepBtn({required this.icon, required this.label, required this.onTap});
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
            color: AppColors.martGreen,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: AppColors.white),
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
        child: Text('home.not_available'.tr(),
            style: AppTextStyles.captionMedium.copyWith(
              color: AppColors.secondaryText,
              fontWeight: AppTextStyles.bold,
            )),
      ),
    );
  }
}
