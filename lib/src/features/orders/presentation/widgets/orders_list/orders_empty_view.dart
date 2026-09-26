import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/widgets/jameia_state_view.dart';

/// No orders yet: the empty state centred in the space the list would take,
/// inside a scrollable that always accepts a drag, so pull-to-refresh still
/// works over it. The height comes from the parent's constraints — no nested
/// unbounded viewport, no intrinsic pass.
class OrdersEmptyView extends StatelessWidget {
  const OrdersEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: constraints.maxHeight,
            child: JameiaStateView(
              message: 'orders.empty'.tr(),
              icon: Icons.receipt_long_outlined,
            ),
          ),
        ],
      ),
    );
  }
}
