import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/route_args/product_detail_args.dart';
import '../../../../../config/routes/routes.dart';
import '../../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../../core/widgets/catalog_cart_gestures.dart';
import '../../../../../core/widgets/catalog_product_card.dart';
import '../../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../cubit/cart_cubit.dart';
import '../../cubit/cart_state.dart';

/// A product of the deals grid: the app's shelf card. "+" adds it (the
/// thumbnail flies into the sheet's basket), "−" takes one out, a tap opens
/// its page (also where a variant is chosen). Only this tile rebuilds when
/// its quantity changes.
class CartDealTile extends StatelessWidget {
  const CartDealTile({super.key, required this.product, required this.width});

  final CatalogProductEntity product;
  final double width;

  void _add(BuildContext context) => CatalogCartGestures.add(
    context,
    image: product.image,
    commit: () => context.read<CartCubit>().addCatalogProduct(product),
  );

  void _remove(BuildContext context) => CatalogCartGestures.remove(
    commit: () => context.read<CartCubit>().removeProduct(product.id),
  );

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
          reservesTagLine: true,
          onTap: () => context.push(
            Routes.productDetail,
            extra: ProductDetailArgs.of(product),
          ),
          onAdd: () => _add(context),
          onRemove: () => _remove(context),
        ),
      ),
    );
  }
}
