import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../cubit/order_tracking_cubit.dart';
import '../widgets/tracking/order_tracking_view.dart';

/// One order's live status (`Routes.orderTracking`, `extra`: order id).
/// Polls while it is the visible page and the order can still move; the
/// poll stops under another page, in the background and on a terminal
/// status.
class OrderTrackingPage extends StatelessWidget {
  const OrderTrackingPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<OrderTrackingCubit>()..load(orderId),
    child: const OrderTrackingView(),
  );
}
