import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/data/models/models.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/widgets/quick_add.dart';
import '../../../product_details/presentation/screens/product_detail_screen.dart';
import '../../../store_mode/presentation/cubit/store_mode_cubit.dart';
import 'product_sku_sheet.dart';

/// A single product row, wired to the cart and VIP/Mart pricing.
///
/// Wraps the presentational [_ShopProductRow] in a
/// [BlocBuilder]&lt;[StoreModeCubit]&gt; so the price updates when the store mode
/// changes (replacing the old `ValueListenableBuilder(repo.isVip)` reach-in),
/// and in a [BlocBuilder]&lt;[CartCubit]&gt; so the stepper quantity stays live.
///
/// TODO(P2.9-boundary): [product] / [shop] stay the core `Product` / `Shop`
/// DTOs — the row pushes the core `Product` into the product-details screen and
/// the cart feature (both typed on the core model).
class ProductRowTile extends StatelessWidget {
  const ProductRowTile({super.key, required this.product, required this.shop});
  final Product product;
  final Shop shop;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CartCubit>();
    // Wrap each product row tile in a RepaintBoundary so a stepper-driven
    // rebuild of one row never repaints its neighbours.
    return RepaintBoundary(
      child: BlocBuilder<StoreModeCubit, StoreModeState>(
        builder: (context, storeMode) {
          final unitPrice = product.priceFor(storeMode.isVip);
          return BlocBuilder<CartCubit, CartState>(
            // Only rebuild THIS row when ITS quantity changes — adding another
            // product must not repaint every row in the list.
            buildWhen: (prev, curr) => product.hasVariants
                ? prev.qtyOfProduct(product.id) != curr.qtyOfProduct(product.id)
                : prev.qtyOf(product.id) != curr.qtyOf(product.id),
            builder: (context, cart) {
              return _ShopProductRow(
                product: product,
                price: unitPrice,
                qty: product.hasVariants
                    ? cart.qtyOfProduct(product.id)
                    : cart.qtyOf(product.id),
                onTap: () => Navigator.of(context).push(
                  KeetaSlideUpRoute(
                    page: ProductDetailScreen(product: product),
                  ),
                ),
                onAdd: !product.available
                    ? null
                    : product.hasVariants
                    ? () => showProductSku(context, product: product)
                    : () => quickAddToCart(
                        context,
                        product: product,
                        unitPrice: unitPrice,
                      ),
                onRemove: product.hasVariants
                    ? () => cubit.removeProduct(product.id)
                    : () => cubit.remove(product.id),
              );
            },
          );
        },
      ),
    );
  }
}

/// Real KeeTa product row in shop menu — matches hc7f46 + b2bc0a atoms:
///   padding: 0 0 0 12dp; row height auto; image 50×50dp, border-radius 13dp (r4);
///   margin-left 20dp between image edge and text block.
/// Pricing is passed in ([price]) so the caller can supply the active VIP/Mart
/// price; unavailable products are dimmed and their add button disabled.
class _ShopProductRow extends StatelessWidget {
  const _ShopProductRow({
    required this.product,
    required this.price,
    required this.qty,
    required this.onAdd,
    required this.onRemove,
    this.onTap,
  });

  final Product product;
  final double price;
  final int qty;
  final VoidCallback? onAdd;
  final VoidCallback onRemove;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final available = product.available;
    return InkWell(
      onTap: onTap, // opens the multi-SKU product detail sheet
      child: Opacity(
        // Dim the whole row when the product is not available.
        opacity: available ? 1 : 0.45,
        child: Padding(
          // hc7f46: padding 0 0 0 12dp; jcf264: padding-right 9dp
          padding: const EdgeInsetsDirectional.only(
            start: 12,
            end: 9,
            top: 12,
            bottom: 12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text block fills all remaining width
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name: KeeTa-SemiBold 14dp #222222 (a4c6b3)
                    Text(
                      product.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headingSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // margin-bottom 2dp (e994fe)
                    const SizedBox(height: 2),
                    // Description: KeeTa-Regular 12dp #808080 — b8abe0 / e847da
                    if (product.desc.isNotEmpty)
                      Text(
                        product.desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.captionLarge.copyWith(
                          color: AppColors.secondaryText,
                          fontSize: AppSize.font12,
                        ),
                      ),
                    const SizedBox(height: 6),
                    // Sold count: 12dp tertiaryText (bfd770: body-small 12dp #999999)
                    Text(
                      Formatters.sold(product.soldCount),
                      style: AppTextStyles.captionLarge.copyWith(
                        color: AppColors.tertiaryText,
                      ),
                    ),
                    const SizedBox(height: 9),
                    // Price row + stepper (fdae8e: margin-top 9dp, space-between)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Price uses the active VIP/Mart price; struck original
                        // price + discount handled by [PriceText] when discounted.
                        Expanded(
                          child: PriceText(
                            price: price,
                            originalPrice: product.hasDiscount
                                ? product.originalPrice
                                : 0,
                            size: 14,
                          ),
                        ),
                        // Qty stepper — disabled add when unavailable.
                        if (available)
                          QtyStepper(
                            qty: qty,
                            onAdd: onAdd ?? () {},
                            onRemove: onRemove,
                            size: 28,
                          )
                        else
                          const _UnavailableTag(),
                      ],
                    ),
                  ],
                ),
              ),
              // margin-left 20dp before thumbnail (b2bc0a: margin-left 20dp)
              const SizedBox(width: 20),
              // Thumbnail: 50×50dp, border-radius 13dp (r4) — b2bc0a atom.
              // KeetaImage wraps itself in a RepaintBoundary, so the image area
              // already isolates its repaints from the surrounding row.
              KeetaImage(
                url: product.image,
                width: 50,
                height: 50,
                radius: AppRadius.r4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Not available" pill shown in place of the stepper for out-of-stock products.
class _UnavailableTag extends StatelessWidget {
  const _UnavailableTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.smallBackground,
        borderRadius: BorderRadius.circular(AppRadius.r4),
      ),
      child: Text(
        'shop.unavailable'.tr(),
        style: AppTextStyles.captionMedium.copyWith(
          color: AppColors.tertiaryText,
        ),
      ),
    );
  }
}
