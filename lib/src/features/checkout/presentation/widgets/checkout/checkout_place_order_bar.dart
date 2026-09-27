import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/fly_to_cart.dart';
import '../../../../../core/widgets/jameia_bottom_bar.dart';
import '../../cubit/checkout_cubit.dart';
import '../../cubit/checkout_state.dart';
import 'checkout_bar_line.dart';
import 'checkout_bar_total.dart';
import 'checkout_place_button.dart';

/// The pinned place-order bar: the total (and the struck total) over the
/// rotating fact line at the start, "Place order" at the end. Three
/// separate widgets, so a rotation, a roll of the total and a change of the
/// button never rebuild one another.
///
/// While checkout is open the total is where products added on the page
/// fly to (the rail's "+"); the previous target comes back when the bar
/// goes.
///
/// Placing empties the cart while this page is still on screen under the
/// tracking page's entrance, so the total and the line freeze from then on:
/// the total keeps the amount just placed, the line stops rotating. Only
/// the button's check still pops.
class CheckoutPlaceOrderBar extends StatefulWidget {
  const CheckoutPlaceOrderBar({super.key});

  @override
  State<CheckoutPlaceOrderBar> createState() => _CheckoutPlaceOrderBarState();
}

class _CheckoutPlaceOrderBarState extends State<CheckoutPlaceOrderBar> {
  final GlobalKey _total = GlobalKey(debugLabel: 'checkout.barTotal');

  @override
  void initState() {
    super.initState();
    FlyToCart.pushTarget(_total);
  }

  @override
  void dispose() {
    FlyToCart.popTarget(_total);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final placed = context.select<CheckoutCubit, bool>(
      (cubit) => cubit.state.status == CheckoutStatus.placed,
    );
    return JameiaBottomBar(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s8,
      ),
      child: Row(
        children: [
          Expanded(
            child: TickerMode(
              enabled: !placed,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KeyedSubtree(key: _total, child: const CheckoutBarTotal()),
                  const SizedBox(height: AppSpacing.s2),
                  const CheckoutBarLine(),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          const CheckoutPlaceButton(),
        ],
      ),
    );
  }
}
