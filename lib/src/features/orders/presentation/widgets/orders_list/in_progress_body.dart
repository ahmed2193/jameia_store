import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design/jameia_icons.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/content_clamp.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../domain/entities/order.dart';
import 'cart_card.dart';
import 'order_card.dart';

/// "In progress" tab body: the current single-store cart (when any) sits on top
/// of the active-order cards. Both empty → the in-progress empty state. The card
/// reacts live to the app-root [CartCubit], so adding/removing items anywhere
/// repaints it here.
class InProgressBody extends StatelessWidget {
  const InProgressBody({super.key, required this.orders});

  final List<OrderEntity> orders;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cart) {
        final hasCart = !cart.isEmpty;
        if (!hasCart && orders.isEmpty) {
          return EmptyStateView(
            message: 'orders.empty_in_progress'.tr(),
            icon: JameiaIcons.orders,
          );
        }
        return ContentClamp(
          child: ListView(
            // Same insets as OrdersList: 12dp horizontal, safe-area bottom.
            padding: EdgeInsetsDirectional.only(
              start: AppSpacing.s12,
              end: AppSpacing.s12,
              bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.s16,
            ),
            children: [
              if (hasCart)
                StaggerEntrance(index: 0, child: CartCard(cart: cart)),
              for (var i = 0; i < orders.length; i++)
                StaggerEntrance(
                  index: hasCart ? i + 1 : i,
                  child: OrderCard(order: orders[i]),
                ),
            ],
          ),
        );
      },
    );
  }
}
