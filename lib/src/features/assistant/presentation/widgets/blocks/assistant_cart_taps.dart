import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/route_args/product_detail_args.dart';
import '../../../../../config/routes/routes.dart';
import '../../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../../core/widgets/catalog_cart_gestures.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';

/// The cart gestures of a product shown in the chat, shared by the rail
/// tile and the wide product card: the app's one add / remove
/// ([CatalogCartGestures] — the thumbnail flies to the app-bar cart) and
/// open, as every other product list.
abstract final class AssistantCartTaps {
  static void add(BuildContext context, CatalogProductEntity product) =>
      CatalogCartGestures.add(
        context,
        image: product.image,
        commit: () => context.read<CartCubit>().addCatalogProduct(product),
      );

  static void remove(BuildContext context, CatalogProductEntity product) =>
      CatalogCartGestures.remove(
        commit: () => context.read<CartCubit>().removeProduct(product.id),
      );

  /// The product page (also where a variant is chosen).
  static void open(BuildContext context, CatalogProductEntity product) =>
      context.push(Routes.productDetail, extra: ProductDetailArgs.of(product));
}
