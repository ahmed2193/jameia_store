import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../core/domain/entities/order_entity.dart';
import '../cubit/courier_tracking_cubit.dart';
import '../cubit/rider_chat_cubit.dart';
import '../cubit/tracking_alerts_cubit.dart';
import '../widgets/live_map/live_map_view.dart';

/// The order's rider, live on a map (`Routes.orderLiveMap`, `extra`: the
/// order) — opened from the order page's "Track on map". The backend has no
/// rider feed yet, so the ride is a simulated one (the data layer's demo
/// feed) on real roads: a rider is found, rides to the store, collects the
/// order, brings it to the door — followed in the notification shade too.
class OrderLiveMapPage extends StatelessWidget {
  const OrderLiveMapPage({super.key, required this.order});

  final OrderEntity order;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => sl<CourierTrackingCubit>()..start(order)),
      BlocProvider(create: (_) => sl<TrackingAlertsCubit>()),
      BlocProvider(create: (_) => sl<RiderChatCubit>()),
    ],
    child: LiveMapView(order: order),
  );
}
