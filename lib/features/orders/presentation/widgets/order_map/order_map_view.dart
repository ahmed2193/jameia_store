import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../cubit/order_tracking_cubit.dart';
import 'order_map_loaded.dart';

class OrderMapView extends StatelessWidget {
  const OrderMapView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mediumBackground,
      body: BlocBuilder<OrderTrackingCubit, OrderTrackingState>(
        builder: (context, state) {
          return switch (state.status) {
            OrderTrackingStatus.initial ||
            OrderTrackingStatus.loading => const AppLoader(),
            OrderTrackingStatus.error => ErrorView(
              message: 'map.order_not_found'.tr(),
              onRetry: () => Navigator.maybePop(context),
            ),
            OrderTrackingStatus.loaded => OrderMapLoaded(
              order: state.order!,
              address: state.address!,
            ),
          };
        },
      ),
    );
  }
}
