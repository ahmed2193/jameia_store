import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/domain/entities/screen_load.dart';
import '../../../../core/motion/haptics.dart';
import '../../../../core/navigation/hero_snack_bar.dart';
import '../../../../core/navigation/screen_failure_listener.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/widgets/cubit_busy_overlay.dart';
import '../../../../core/widgets/hero_title_bar.dart';
import '../../../../core/widgets/reconnect_refresh.dart';
import '../cubit/order_review_cubit.dart';
import '../cubit/order_review_state.dart';
import '../widgets/order_detail_state_switcher.dart';
import '../widgets/review/review_body.dart';

/// Rate the products of a delivered order (`Routes.orderReview`, `extra`:
/// order id) — one `POST /v1/reviews` per rated product. On success the
/// page thanks the customer (a success haptic, the busy overlay's check) and
/// closes. The order saved on the device shows at once; a submit that fails
/// offline keeps the stars and the comment and says so.
class OrderReviewPage extends StatelessWidget {
  const OrderReviewPage({super.key, required this.orderId});

  final String orderId;

  void _onSubmitted(BuildContext context, OrderReviewState state) {
    Haptics.success();
    showHeroSnackBar(context, 'orders.review_thanks'.tr());
    context.pop();
  }

  static void _signIn(BuildContext context) => context.go(Routes.login);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OrderReviewCubit>()..load(orderId),
      child: BlocListener<OrderReviewCubit, OrderReviewState>(
        listenWhen: (previous, current) =>
            !previous.submitted && current.submitted,
        listener: _onSubmitted,
        child: ScreenFailureListener<OrderReviewCubit, OrderReviewState>(
          onUnauthorized: _signIn,
          // Sending holds the screen; the check shows as the page closes.
          child: CubitBusyOverlay<OrderReviewCubit, OrderReviewState>(
            busyOf: (state) => state.isSubmitting,
            doneOf: (state) => state.submitted,
            doneLabel: 'orders.review_thanks'.tr(),
            child: Scaffold(
              backgroundColor: AppColors.white,
              appBar: HeroTitleBar(title: 'orders.review_title'.tr()),
              body: ContentClamp(
                // Below the provider: the page's own context is above it.
                child: Builder(
                  builder: (context) => ReconnectRefresh(
                    onReconnected: () =>
                        context.read<OrderReviewCubit>().onReconnected(),
                    child: BlocBuilder<OrderReviewCubit, OrderReviewState>(
                      buildWhen: (previous, current) =>
                          current.load.screenChangedFrom(previous.load) ||
                          previous.order != current.order,
                      builder: (context, state) {
                        final order = state.order;
                        return OrderDetailStateSwitcher(
                          content:
                              state.status == LoadPhase.loaded && order != null
                              ? ReviewBody(order: order)
                              : null,
                          failure: state.loadFailure,
                          isSignedOut: state.isSignedOut,
                          onRetry: () =>
                              context.read<OrderReviewCubit>().load(orderId),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
