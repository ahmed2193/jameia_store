import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/hero_title_bar.dart';
import '../../cubit/order_tracking_cubit.dart';
import '../../cubit/order_tracking_state.dart';
import 'tracking_help_action.dart';

/// The order page's title bar: the order number once it is known ("Order
/// HX-10234", before: "Order details"), and "Help" at the end. Rebuilds only
/// when the number arrives.
class TrackingTitleBar extends StatelessWidget implements PreferredSizeWidget {
  const TrackingTitleBar({super.key, required this.onHelp});

  final VoidCallback onHelp;

  @override
  Size get preferredSize => const Size.fromHeight(HeroTitleBar.height);

  @override
  Widget build(BuildContext context) {
    return BlocSelector<OrderTrackingCubit, OrderTrackingState, String?>(
      selector: (state) => state.order?.orderNumber,
      builder: (context, number) => HeroTitleBar(
        title: number == null
            ? 'orders.details_title'.tr()
            : 'orders.order_no'.tr(
                namedArgs: {'number': Formatters.isolate(number)},
              ),
        actions: [TrackingHelpAction(onPressed: onHelp)],
      ),
    );
  }
}
