import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/motion/fly_to_cart.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/catalog_product_card.dart';
import '../../../../core/widgets/jameia_card_image.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/cubit/cart_state.dart';

/// A related product wired to the app-global cart. Only THIS tile rebuilds when
/// its quantity changes, and it repaints on its own.
class PdpRelatedTile extends StatelessWidget {
  const PdpRelatedTile({
    super.key,
    required this.product,
    required this.pro,
    required this.onOpen,
  });

  final CatalogProductEntity product;
  final bool pro;
  final ValueChanged<CatalogProductEntity> onOpen;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: BlocSelector<CartCubit, CartState, int>(
        selector: (cart) => cart.qtyOfProduct(product.id),
        builder: (context, qty) => CatalogProductCard(
          product: product,
          qty: qty,
          pro: pro,
          onTap: () => onOpen(product),
          onAdd: () {
            HapticFeedback.selectionClick();
            // The same add gesture as every other list in the app.
            FlyToCart.flyFrom(
              context,
              thumbnail: JameiaCardImage(
                url: product.image,
                width: AppSize.s56,
                height: AppSize.s56,
                radius: AppRadius.r4,
              ),
            );
            context.read<CartCubit>().addCatalogProduct(product);
          },
          onRemove: () {
            HapticFeedback.lightImpact();
            context.read<CartCubit>().removeProduct(product.id);
          },
        ),
      ),
    );
  }
}
