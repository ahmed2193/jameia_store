import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/data/models/models.dart';
import '../../../../core/design/jameia_assets.dart';
import '../../../../core/design/jameia_icons.dart';
import '../../../../core/motion/fly_to_cart.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../store_mode/presentation/cubit/store_mode_cubit.dart';
import '../cubit/shop_sku_cubit.dart';

/// Cart supplier id for the jm3eia offline catalogue — the `shopId` every shop
/// add-to-cart flow tags its lines with. Kept as a shop-feature const (mirrors
/// the cart's canonical `'jameia'` supplier) so this feature's presentation no
/// longer imports `core/data/jameia_repository.dart` just for the constant.
const String kShopSupplierId = 'jameia';

/// Jameia multi-SKU product-detail modal (`shop_multi_sku_modal_global`).
///
/// Opens from a shop menu row: shows the product image / name / price /
/// description, a size (variant) selector when the product has SKUs, a quantity
/// stepper and a full-width add-to-cart CTA. All selection/quantity/price state
/// lives in [ShopSkuCubit]; the sheet is a thin [BlocProvider] + [BlocBuilder]
/// view. Adds the chosen variant to the cart via [CartCubit].
Future<void> showProductSku(
  BuildContext context, {
  required Product product,
  String shopId = kShopSupplierId,
}) {
  final cart = context.read<CartCubit>();
  // Active store mode read once from the global StoreModeCubit (root-provided),
  // replacing the old `sl<JameiaRepository>().isVip` reach-in.
  final isVip = context.read<StoreModeCubit>().state.isVip;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    barrierColor: AppColors.overlayPrimary,
    shape: const RoundedRectangleBorder(
      // Real sku-modal sheet top radius 12dp (atom e1d294), not the 24dp sheet token.
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
    ),
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider<CartCubit>.value(value: cart),
        BlocProvider<ShopSkuCubit>(
          create: (_) =>
              ShopSkuCubit(product: product, shopId: shopId, isVip: isVip),
        ),
      ],
      child: _ProductSkuSheet(product: product),
    ),
  );
}

class _ProductSkuSheet extends StatefulWidget {
  const _ProductSkuSheet({required this.product});
  final Product product;

  @override
  State<_ProductSkuSheet> createState() => _ProductSkuSheetState();
}

class _ProductSkuSheetState extends State<_ProductSkuSheet> {
  // Anchors the header thumbnail so the fly-to-cart flight starts from it.
  final GlobalKey _imageKey = GlobalKey();

  void _addToCart(ShopSkuState sku) {
    final sheetCubit = context.read<ShopSkuCubit>();
    sheetCubit.addToCart(context.read<CartCubit>());
    // Arc the chosen product's thumbnail into the cart badge before the sheet
    // closes (reduced-motion safe → no-op).
    FlyToCart.fly(
      context,
      sourceKey: _imageKey,
      thumbnail: JameiaCardImage(
        url: sku.image,
        width: 56,
        height: 56,
        radius: AppRadius.r4,
      ),
    );
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxH = MediaQuery.sizeOf(context).height * 0.82;

    return BlocBuilder<ShopSkuCubit, ShopSkuState>(
      builder: (context, sku) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Grab handle ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  top: AppSpacing.s12,
                  bottom: AppSpacing.s4,
                ),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              // ── Scrollable content ────────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.s16,
                    AppSpacing.s8,
                    AppSpacing.s16,
                    AppSpacing.s16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: image + name/price/sold + close.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          JameiaCardImage(
                            key: _imageKey,
                            url: sku.image,
                            width: 96,
                            height: 96,
                            radius: AppRadius.r3,
                          ),
                          const SizedBox(width: AppSpacing.s12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.displayName,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.headingMedium.copyWith(
                                    fontWeight: AppTextStyles.bold,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.s4),
                                if (p.soldCount > 0)
                                  Text(
                                    Formatters.sold(p.soldCount),
                                    style: AppTextStyles.captionLarge.copyWith(
                                      color: AppColors.tertiaryText,
                                    ),
                                  ),
                                const SizedBox(height: AppSpacing.s6),
                                PriceText(
                                  price: sku.unitPrice,
                                  originalPrice: sku.oldPrice,
                                  size: 20,
                                  // sku-modal price is brown #713901 (atom fa812e).
                                  color: AppColors.skuOptionFg,
                                  // In-place summary price flips when the chosen
                                  // variant (and thus price) changes.
                                  animate: true,
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).maybePop(),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: AppSpacing.s8,
                              ),
                              child: Image.asset(
                                JameiaAssets.skuClose,
                                width: 20,
                                height: 20,
                                errorBuilder: (_, _, _) => const Icon(
                                  JameiaIcons.close,
                                  size: 20,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Description.
                      if (p.desc.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.s12),
                        Text(
                          p.desc,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.secondaryText,
                            height: 1.4,
                          ),
                        ),
                      ],

                      // Variant (size) selector.
                      if (p.hasVariants) ...[
                        const SizedBox(height: AppSpacing.s16),
                        const ThinDivider(),
                        const SizedBox(height: AppSpacing.s12),
                        Text(
                          'shop.options'.tr(),
                          style: AppTextStyles.headingSmall.copyWith(
                            fontWeight: AppTextStyles.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s10),
                        Wrap(
                          spacing: AppSpacing.s8,
                          runSpacing: AppSpacing.s8,
                          children: [
                            for (var i = 0; i < p.variants.length; i++)
                              _VariantChip(
                                variant: p.variants[i],
                                selected: i == sku.variantIndex,
                                onTap: p.variants[i].inStock
                                    ? () => context
                                          .read<ShopSkuCubit>()
                                          .selectVariant(i)
                                    : null,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Bottom action bar: qty stepper + add-to-cart CTA ───────────
              const ThinDivider(),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.s16,
                  AppSpacing.s12,
                  AppSpacing.s16,
                  AppSpacing.s12 +
                      (bottomInset > 0 ? bottomInset : AppSpacing.s4),
                ),
                child: Row(
                  children: [
                    _SkuStepper(
                      qty: sku.quantity,
                      onAdd: () => context.read<ShopSkuCubit>().increment(),
                      onRemove: () => context.read<ShopSkuCubit>().decrement(),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: GestureDetector(
                        onTap: sku.canAdd ? () => _addToCart(sku) : null,
                        child: AnimatedContainer(
                          duration: MotionGuard.duration(
                            context,
                            AppMotion.fast,
                          ),
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: sku.canAdd
                                ? AppColors.primary
                                : AppColors.divider,
                            borderRadius: BorderRadius.circular(AppRadius.r3),
                          ),
                          child: Text(
                            sku.canAdd
                                ? 'shop.add_price'.tr(
                                    namedArgs: {
                                      'price': Formatters.price(
                                        sku.unitPrice * sku.quantity,
                                      ),
                                    },
                                  )
                                : 'shop.out_of_stock'.tr(),
                            style: AppTextStyles.headingMedium.copyWith(
                              fontWeight: AppTextStyles.bold,
                              color: sku.canAdd
                                  ? AppColors.brandForeground
                                  : AppColors.tertiaryText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// SKU-modal quantity stepper (`i9bfef`): a #F0F1F5 r16 pill with the real
/// `icon_multi_sku_dec` / `icon_multi_sku_add` buttons around the count.
class _SkuStepper extends StatelessWidget {
  const _SkuStepper({
    required this.qty,
    required this.onAdd,
    required this.onRemove,
  });

  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final canDec = qty > 1;
    return Container(
      height: 44,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.smallBackground,
        borderRadius: BorderRadius.circular(AppRadius.r3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepBtn(
            asset: canDec ? JameiaAssets.skuDec : JameiaAssets.skuDecDisabled,
            fallback: Icons.remove_rounded,
            label: 'shop.decrease_quantity'.tr(),
            onTap: canDec ? onRemove : null,
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 36),
            alignment: Alignment.center,
            child: Text(
              '$qty',
              style: AppTextStyles.headingSmall.copyWith(
                fontWeight: AppTextStyles.bold,
              ),
            ),
          ),
          _StepBtn(
            asset: JameiaAssets.skuAdd,
            fallback: Icons.add_rounded,
            label: 'shop.increase_quantity'.tr(),
            onTap: onAdd,
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({
    required this.asset,
    required this.fallback,
    required this.label,
    this.onTap,
  });
  final String asset;
  final IconData fallback;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        // 40dp min tap target around the 30dp glyph (a11y).
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Opacity(
            opacity: onTap == null ? 0.4 : 1,
            child: Image.asset(
              asset,
              width: 30,
              height: 30,
              errorBuilder: (_, _, _) =>
                  Icon(fallback, size: 22, color: AppColors.primaryText),
            ),
          ),
        ),
      ),
    );
  }
}

/// A selectable variant (size/option) pill — yellow when selected, struck-through
/// grey when out of stock.
class _VariantChip extends StatelessWidget {
  const _VariantChip({
    required this.variant,
    required this.selected,
    required this.onTap,
  });

  final ProductVariant variant;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Reference `be15a6`/`bbbce5`: r4, brown #713901 border+text; selected fills
    // brand yellow; out-of-stock is greyed + struck through.
    final disabled = onTap == null;
    final Color bg;
    final Color fg;
    final Color border;
    if (selected) {
      bg = AppColors.primary;
      fg = AppColors.skuOptionFg;
      border = AppColors.primary;
    } else if (disabled) {
      bg = AppColors.smallBackground;
      fg = AppColors.disabledText;
      border = AppColors.divider;
    } else {
      bg = AppColors.white;
      fg = AppColors.skuOptionFg;
      border = AppColors.skuOptionFg;
    }
    return Semantics(
      button: true,
      selected: selected,
      enabled: !disabled,
      label: variant.label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 40),
          // be15a6: 22.5dp (kept ~24 for a touch-friendly target).
          height: 24,
          alignment: Alignment.center,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s8,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppSize.r4),
            border: Border.all(color: border, width: 0.5),
          ),
          child: Text(
            variant.label,
            style: TextStyle(
              fontSize: AppSize.font12,
              color: fg,
              fontWeight: selected ? AppTextStyles.bold : AppTextStyles.regular,
              decoration: disabled ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
      ),
    );
  }
}
