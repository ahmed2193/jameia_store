import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/domain/entities/order_entity.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/widgets/reconnect_refresh.dart';
import '../../cubit/courier_tracking_cubit.dart';
import '../../cubit/courier_tracking_state.dart';
import 'live_map_alerts.dart';
import 'live_map_body.dart';

/// The live map screen's frame: dark status bar icons over the map, the
/// ride's moments and notifications ([LiveMapAlerts]), a feed that broke on
/// the way told once, and the connection coming back following the rider
/// again.
class LiveMapView extends StatelessWidget {
  const LiveMapView({super.key, required this.order});

  final OrderEntity order;

  static void _tellFailure(BuildContext context, CourierTrackingState state) {
    final failure = state.failure;
    if (failure != null) showFailureSnackBar(context, failure);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: ReconnectRefresh(
        onReconnected: () =>
            context.read<CourierTrackingCubit>().onReconnected(),
        child: BlocListener<CourierTrackingCubit, CourierTrackingState>(
          listenWhen: (before, now) =>
              now.status == CourierTrackingStatus.live &&
              now.failure != null &&
              before.failure != now.failure,
          listener: _tellFailure,
          child: LiveMapAlerts(
            order: order,
            child: const Scaffold(
              backgroundColor: AppColors.smallBackground,
              // The only keyboard here is the chat sheet's: the map and its
              // panel stay as they are under it (no native map resize, no
              // re-aim, frame after frame).
              resizeToAvoidBottomInset: false,
              body: LiveMapBody(),
            ),
          ),
        ),
      ),
    );
  }
}
