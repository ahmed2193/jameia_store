import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/route_args/product_detail_args.dart';
import '../../../../../config/routes/routes.dart';
import '../../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../../core/motion/fly_to_cart.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/widgets/catalog_product_card.dart';
import '../../../../../core/widgets/jameia_image.dart';
import '../../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../../cart/presentation/cubit/cart_state.dart';

/// One product of the checkout rail, wired to the app-global cart: "+" adds
/// it (its picture flies into the bar's total, at the card's own image size
/// so the flight is a cache hit), "−" takes one out, a tap opens its page —
/// also where a product with sizes is chosen (the card kit sends its "+"
/// there). Only this tile rebuilds when its quantity changes; the list's
/// viewport already isolates its repaints.
class CheckoutRailTile extends StatelessWidget {
  const CheckoutRailTile({super.key, required this.product});

  final CatalogProductEntity product;

  void _add(BuildContext context) {
    Haptics.selection();
    FlyToCart.flyFrom(
      context,
      thumbnail: JameiaImage(
        url: product.image,
        width: CatalogProductCard.defaultWidth,
        height: CatalogProductCard.defaultWidth,
      ),
    );
    context.read<CartCubit>().addCatalogProduct(product);
  }

  void _remove(BuildContext context) {
    Haptics.selection();
    context.read<CartCubit>().removeProduct(product.id);
  }

  @override
  Widget build(BuildContext context) {
    final isPro = context.select<AuthSessionCubit, bool>(
      (session) => session.state.customer?.isPro ?? false,
    );
    return BlocSelector<CartCubit, CartState, int>(
      selector: (cart) => cart.qtyOfProduct(product.id),
      builder: (context, qty) => CatalogProductCard(
        product: product,
        qty: qty,
        pro: isPro,
        onTap: () => context.push(
          Routes.productDetail,
          extra: ProductDetailArgs.of(product),
        ),
        onAdd: () => _add(context),
        onRemove: () => _remove(context),
      ),
    );
  }
}
