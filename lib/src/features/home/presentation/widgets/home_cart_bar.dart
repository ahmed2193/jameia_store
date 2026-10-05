import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/motion/collapse_reveal.dart';
import '../../../../core/motion/deferred_value.dart';
import '../../../../core/motion/motion_beat.dart';
import '../../../../core/navigation/hero_snack_bar.dart';
import '../../../../core/utils/formatters.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/cubit/cart_state.dart';
import '../cubit/home_cubit.dart';
import 'home_min_order_bar.dart';

/// The bar under the home feed, above the shell tab bar: while the basket is
/// empty it tells the customer how much to start adding — the store's
/// minimum order from the launch snapshot. Nothing shows while that minimum
/// is unknown, and nothing once the basket has items: the Cart tab carries
/// the basket from there. The bar rises out of the bottom edge when it
/// comes, and sinks back into it when it goes — the one bottom-bar timing
/// ([CollapseReveal]: in medium, out fast), same as every catalogue page.
/// After the first add it folds last (backlog B2-03: [MotionBeat.at] 3 —
/// after the flight and the confetti have started). One bar at a time on
/// the tab bar: while the customer is due the first-order gift its bar
/// stands there instead (its details tell the minimum), and this one folds
/// at once to make room.
class HomeCartBar extends StatelessWidget {
  const HomeCartBar({super.key});

  @override
  Widget build(BuildContext context) {
    final minOrderKd = context.select<HomeCubit, double>(
      (cubit) => cubit.state.bootstrap.delivery?.minOrderKd ?? 0,
    );
    final giftBar = context.select<HomeCubit, bool>(
      (cubit) => cubit.state.firstOrderGift,
    );
    return BlocSelector<CartCubit, CartState, bool>(
      selector: (cart) => cart.isEmpty,
      builder: (context, isEmpty) {
        final amount = Formatters.price(minOrderKd);
        return DeferredValue<bool>(
          value: isEmpty && minOrderKd > 0 && !giftBar,
          delay: MotionBeat.at(3),
          // Only the fold after an add waits; the bar comes back at once,
          // and makes room for the gift bar at once.
          deferWhen: (shown, next) => shown && !next && !giftBar,
          builder: (context, show) => CollapseReveal(
            visible: show,
            alignment: AlignmentDirectional.topCenter,
            child: show
                ? HomeMinOrderBar(
                    message: 'home.start_adding'.tr(
                      namedArgs: {'amount': amount},
                    ),
                    onInfo: () => showHeroSnackBar(
                      context,
                      'home.min_order_info'.tr(namedArgs: {'amount': amount}),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
