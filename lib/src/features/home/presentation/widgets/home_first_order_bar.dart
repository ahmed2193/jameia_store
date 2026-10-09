import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/motion/collapse_reveal.dart';
import '../cubit/first_order_bar_cubit.dart';
import 'home_first_order_banner.dart';
import 'home_popup_queue.dart';

/// The first-order free-delivery bar on the main shell's tab bar: there
/// while the customer is still due the gift ([FirstOrderBarCubit], fed by
/// the home tab) on a tab where it belongs ([here]), gone once their first
/// order is placed. It rises out of the tab bar when it comes and sinks back
/// into it when it goes ([CollapseReveal], the one bottom-bar timing) — so
/// it also sinks away on the way to the Cart tab and rises again after. A
/// tap opens the welcome-gift GIF popup again
/// ([HomePopupQueue.showWelcome]); "Order now" there just closes it.
class HomeFirstOrderBar extends StatelessWidget {
  const HomeFirstOrderBar({super.key, this.here = true});

  final bool here;

  @override
  Widget build(BuildContext context) {
    final due = context.select<FirstOrderBarCubit, bool>(
      (cubit) => cubit.state,
    );
    final shows = due && here;
    return CollapseReveal(
      visible: shows,
      alignment: AlignmentDirectional.topCenter,
      child: shows
          ? HomeFirstOrderBanner(
              onTap: () => HomePopupQueue.showWelcome(context),
            )
          : const SizedBox.shrink(),
    );
  }
}
