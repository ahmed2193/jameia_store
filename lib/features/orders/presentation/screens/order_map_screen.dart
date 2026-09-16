import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/service_locator.dart';
import '../cubit/order_tracking_cubit.dart';
import '../widgets/order_map/order_map_view.dart';

/// KeeTa standalone full-screen order map (`mach_pro_sailor_c_order_map_golden`,
/// alias `c_order_map`).
///
/// 1:1 clone of the "golden path" live-delivery map opened from order status:
/// shop pin + user/destination pin + a HEADING-ROTATED rider marker, the route
/// polyline (`KeetaGeocode.routePolyline`, width 4), a floating ETA bubble, a
/// re-center FAB, an open-in-maps FAB, and a compact bottom card surfacing the
/// ETA, the rider row (call + chat) and drop-off / platform fee.
///
/// GESTURE-SAFE LAYOUT (RE §0.1, §8): the `KeetaMap` is sized to ONLY the region
/// ABOVE the bottom card — never `Positioned.fill` behind a tappable sheet — so
/// the Android platform view never steals the card's / FABs' touches.
class OrderMapScreen extends StatelessWidget {
  const OrderMapScreen({super.key, this.orderId = 'o1'});

  /// Order id resolved from the dummy repository (router passes the tapped id).
  final String orderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OrderTrackingCubit>()..load(orderId),
      child: const OrderMapView(),
    );
  }
}
