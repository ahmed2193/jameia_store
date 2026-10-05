import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/motion/collapse_reveal.dart';
import '../cubit/home_cubit.dart';
import 'home_first_order_banner.dart';
import 'home_first_order_offer.dart';

/// The home tab's first-order free-delivery bar, right on the shell's tab
/// bar: there while the customer is still due the gift
/// ([HomeState.firstOrderGift]: the store runs it and they have no order
/// yet), gone once their first order is placed. It rises out of the tab bar
/// when it comes and sinks back into it when it goes ([CollapseReveal], the
/// one bottom-bar timing). A tap opens the details
/// ([HomeFirstOrderOffer.show]).
class HomeFirstOrderBar extends StatelessWidget {
  const HomeFirstOrderBar({super.key});

  @override
  Widget build(BuildContext context) {
    final due = context.select<HomeCubit, bool>(
      (cubit) => cubit.state.firstOrderGift,
    );
    return CollapseReveal(
      visible: due,
      alignment: AlignmentDirectional.topCenter,
      child: due
          ? HomeFirstOrderBanner(onTap: () => HomeFirstOrderOffer.show(context))
          : const SizedBox.shrink(),
    );
  }
}
