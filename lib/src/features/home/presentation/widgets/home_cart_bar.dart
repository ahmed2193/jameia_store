import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/motion/motion.dart';
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
/// comes, and sinks back into it when it goes.
class HomeCartBar extends StatelessWidget {
  const HomeCartBar({super.key});

  @override
  Widget build(BuildContext context) {
    final minOrderKd = context.select<HomeCubit, double>(
      (cubit) => cubit.state.bootstrap.delivery?.minOrderKd ?? 0,
    );
    return BlocSelector<CartCubit, CartState, bool>(
      selector: (cart) => cart.isEmpty,
      builder: (context, isEmpty) {
        final show = isEmpty && minOrderKd > 0;
        final amount = Formatters.price(minOrderKd);
        return AnimatedSwitcher(
          duration: MotionGuard.duration(context, AppMotion.slow),
          switchInCurve: AppMotion.emphasizedDecelerate,
          switchOutCurve: AppMotion.exit,
          // Rises out of the bottom edge, and sinks back into it.
          transitionBuilder: (child, animation) => SizeTransition(
            sizeFactor: animation,
            alignment: Alignment.topCenter,
            child: FadeTransition(opacity: animation, child: child),
          ),
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
        );
      },
    );
  }
}
