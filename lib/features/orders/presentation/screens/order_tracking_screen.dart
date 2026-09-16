import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/service_locator.dart';
import '../cubit/order_tracking_cubit.dart';
import '../widgets/tracking/order_tracking_view.dart';

/// KeeTa order tracking / order-detail screen (`mach_pro_sailor_c_order_status_global`).
///
/// 1:1 clone of the live-tracking page: styled live-map placeholder (real KeeTa
/// rider/shop/user markers), confirm→prepare→pickup→on-the-way→delivered progress
/// stepper bound to [KeetaOrder.statusStep], ETA bubble, rider action bar
/// (call + chat), order summary (items / total / payment), delivery address from
/// [KeetaRepository.defaultAddress], and a help / refund entry.
///
/// [KeetaOrder] has no payment/address fields, so the payment row uses a static
/// label and the address row reads the default address.
class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key, this.orderId = 'o1'});

  /// Order id resolved from the dummy repository (router passes the tapped id).
  final String orderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OrderTrackingCubit>()..load(orderId),
      child: const OrderTrackingView(),
    );
  }
}
