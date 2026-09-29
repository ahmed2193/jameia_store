import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../core/domain/entities/cart_item_request.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/widgets/catalog_cart_gestures.dart';
import '../../../../../core/widgets/hero_bottom_bar.dart';
import '../../../../../core/widgets/hero_submit_button.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../../cart/presentation/cubit/cart_state.dart';

/// "Reorder" at the foot of a finished order (delivered or cancelled): puts
/// every paid line back in the cart in one request, then opens the cart so
/// the customer can check it before checking out — the delivery apps' flow.
/// The pill holds its label with the dots while the cart answers; a failure
/// is told the cart's way (a snack; offline: the connection banner).
class TrackingReorderBar extends StatelessWidget {
  const TrackingReorderBar({
    super.key,
    required this.items,
    required this.image,
  });

  final List<CartItemRequest> items;

  /// The photo that flies to a cart on screen once the lines are in.
  final String image;

  Future<void> _reorder(BuildContext context) async {
    final cart = context.read<CartCubit>();
    final added = await cart.addItems(items);
    if (!context.mounted) return;
    if (added) {
      // The add-to-cart gesture of every product surface (a flight only
      // when a cart shows), then the cart — after the landing.
      await CatalogCartGestures.added(context, image: image);
      if (!context.mounted) return;
      await context.push(Routes.cartPreview);
      return;
    }
    final failure = cart.state.failure;
    if (failure != null) showFailureSnackBar(context, failure, action: true);
  }

  @override
  Widget build(BuildContext context) {
    final reordering = context.select<CartCubit, bool>(
      (cubit) => cubit.state.busyAction == CartAction.addItems,
    );
    return HeroBottomBar(
      child: HeroSubmitButton(
        label: 'orders.reorder'.tr(),
        sticker: true,
        loading: reordering,
        enabled: items.isNotEmpty,
        onPressed: () => _reorder(context),
      ),
    );
  }
}
