import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/motion/fly_to_cart.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/catalog_product_card.dart';
import '../../../../core/widgets/jameia_card_image.dart';
import '../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/cubit/cart_state.dart';

/// One product of a home rail wired to the app-global cart: only THIS tile
/// rebuilds when its quantity changes (a [BlocSelector] on its own count), and
/// it is repaint-isolated from its neighbours.
class HomeProductTile extends StatelessWidget {
  const HomeProductTile({
    super.key,
    required this.product,
    required this.width,
    required this.onOpen,
  });

  final CatalogProductEntity product;
  final double width;
  final ValueChanged<CatalogProductEntity> onOpen;

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
          onTap: () => onOpen(product),
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
