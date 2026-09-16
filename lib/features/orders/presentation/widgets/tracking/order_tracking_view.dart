import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/brand_moment.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../cubit/order_tracking_cubit.dart';
import 'tracking_loaded_view.dart';

class OrderTrackingView extends StatefulWidget {
  const OrderTrackingView({super.key});

  @override
  State<OrderTrackingView> createState() => _OrderTrackingViewState();
}

class _OrderTrackingViewState extends State<OrderTrackingView> {
  // Drives the one-shot "delivered" brand moment overlay.
  bool _showDeliveredMoment = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mediumBackground,
      // Celebrate the natural confirm point: when the live simulation reaches
      // "Delivered" (statusStep 5) we flash the KeeTa pay-success tick once.
      body: BlocListener<OrderTrackingCubit, OrderTrackingState>(
        listenWhen: (prev, next) =>
            prev.status == OrderTrackingStatus.loaded &&
            next.status == OrderTrackingStatus.loaded &&
            (prev.order?.statusStep ?? 0) < 5 &&
            (next.order?.statusStep ?? 0) >= 5,
        listener: (context, state) =>
            setState(() => _showDeliveredMoment = true),
        child: Stack(
          children: [
            BlocBuilder<OrderTrackingCubit, OrderTrackingState>(
              builder: (context, state) {
                return switch (state.status) {
                  OrderTrackingStatus.initial ||
                  OrderTrackingStatus.loading => const AppLoader(),
                  OrderTrackingStatus.error => ErrorView(
                    message: 'map.order_not_found'.tr(),
                    onRetry: () => Navigator.maybePop(context),
                  ),
                  OrderTrackingStatus.loaded => TrackingLoadedView(
                    order: state.order!,
                    address: state.address!,
                  ),
                };
              },
            ),
            if (_showDeliveredMoment)
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                    color: AppColors.black.withValues(alpha: 0.04),
                    child: Center(
                      child: BrandMoment(
                        kind: BrandMomentKind.paySuccess,
                        size: 96,
                        onComplete: () {
                          if (mounted) {
                            setState(() => _showDeliveredMoment = false);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
