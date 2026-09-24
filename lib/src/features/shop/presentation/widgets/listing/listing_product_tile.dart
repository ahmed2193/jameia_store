import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/route_args/product_detail_args.dart';
import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../../core/motion/fly_to_cart.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/catalog_product_card.dart';
import '../../../../../core/widgets/jameia_card_image.dart';
import '../../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../../cart/presentation/cubit/cart_state.dart';

/// One product of a listing grid wired to the app-global cart. Only THIS tile
/// rebuilds when its quantity changes, and it repaints on its own.
class ListingProductTile extends StatelessWidget {
  const ListingProductTile({
    super.key,
    required this.product,
    required this.width,
  });

  final CatalogProductEntity product;
  final double width;

  @override
  Widget build(BuildContext context) {
    final isPro = context.select<AuthSessionCubit, bool>(
      (session) => session.state.customer?.isPro ?? false,
    );
    return RepaintBoundary(
      child: BlocSelector<CartCubit, CartState, int>(
        selector: (cart) => cart.qtyOfProduct(product.id),
        builder: (context, qty) => CatalogProductCard(
          product: product,
          qty: qty,
          pro: isPro,
          width: width,
          onTap: () => context.push(
            Routes.productDetail,
            extra: ProductDetailArgs.of(product),
          ),
          onAdd: () {
            HapticFeedback.selectionClick();
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
