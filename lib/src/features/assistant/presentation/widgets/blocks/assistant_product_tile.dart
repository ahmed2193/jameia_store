import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../../core/widgets/catalog_product_card.dart';
import '../../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../../cart/presentation/cubit/cart_state.dart';
import 'assistant_cart_taps.dart';

/// A catalogue card in the chat. It is a normal product tile, NOT a
/// proposal: + adds through the app cart at once (thumbnail flies to the
/// app-bar cart), a tap opens the product. Only this tile rebuilds when its
/// quantity changes.
///
/// (The same cart wiring exists per feature — home, listing, PDP — because
/// a core widget may not read the cart feature's cubit.)
class AssistantProductTile extends StatelessWidget {
  const AssistantProductTile({super.key, required this.product});

  final CatalogProductEntity product;

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
          onTap: () => AssistantCartTaps.open(context, product),
          onAdd: () => AssistantCartTaps.add(context, product),
          onRemove: () => AssistantCartTaps.remove(context, product),
        ),
      ),
    );
  }
}
