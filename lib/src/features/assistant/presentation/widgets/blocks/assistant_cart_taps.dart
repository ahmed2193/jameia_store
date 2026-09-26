import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/route_args/product_detail_args.dart';
import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../../core/motion/fly_to_cart.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/jameia_card_image.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';

/// The cart gestures of a product shown in the chat, shared by the rail
/// tile and the wide product card: the same add (thumbnail flies to the
/// app-bar cart), remove and open as every other product list.
abstract final class AssistantCartTaps {
  static void add(BuildContext context, CatalogProductEntity product) {
    Haptics.selection();
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
  }

  static void remove(BuildContext context, CatalogProductEntity product) {
    Haptics.tap();
    context.read<CartCubit>().removeProduct(product.id);
  }

  /// The product page (also where a variant is chosen).
  static void open(BuildContext context, CatalogProductEntity product) =>
      context.push(Routes.productDetail, extra: ProductDetailArgs.of(product));
}
