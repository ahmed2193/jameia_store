import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_args/product_detail_args.dart';
import '../../../../config/routes/routes.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/motion/press_scale.dart';
import '../../../../core/widgets/catalog_cart_gestures.dart';
import '../../../../core/widgets/shelf_product_card.dart';
import '../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/cubit/cart_state.dart';

/// One product of a rail under the product, wired to the app-global cart the
/// way a listing card is: open its page, add (flying into the cart), remove.
/// A rail is one row, so the card skips the empty tag line. Only THIS tile
/// rebuilds when its quantity changes, and it repaints on its own. The card
/// sinks a touch under the finger and lets go as soon as the finger scrolls
/// the rail.
class PdpRailTile extends StatelessWidget {
  const PdpRailTile({super.key, required this.product, required this.width});

  final CatalogProductEntity product;
  final double width;

  @override
  Widget build(BuildContext context) {
    final isPro = context.select<AuthSessionCubit, bool>(
      (session) => session.state.customer?.isPro ?? false,
    );
    return RepaintBoundary(
      // Passive: the card keeps its own taps (open, add, remove).
      child: PressScale(
        child: BlocSelector<CartCubit, CartState, int>(
          selector: (cart) => cart.qtyOfProduct(product.id),
          builder: (context, qty) => ShelfProductCard(
            product: product,
            qty: qty,
            pro: isPro,
            width: width,
            reservesTagLine: false,
            onTap: () => context.push(
              Routes.productDetail,
              extra: ProductDetailArgs.of(product),
            ),
            onAdd: () => CatalogCartGestures.add(
              context,
              image: product.image,
              commit: () =>
                  context.read<CartCubit>().addCatalogProduct(product),
            ),
            onRemove: () => CatalogCartGestures.remove(
              commit: () => context.read<CartCubit>().removeProduct(product.id),
            ),
          ),
        ),
      ),
    );
  }
}
