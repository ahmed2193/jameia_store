import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/domain/entities/screen_load.dart';
import '../../../../core/motion/haptics.dart';
import '../../../../core/motion/success_beat.dart';
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
  const OrderReviewPage({
    super.key,
    required this.orderId,
    this.initialRating = 0,
  });

  final String orderId;

  /// Stars already tapped on the order page (1–5): every product starts
  /// there; 0 = none.
  final int initialRating;

  /// The overlay's check holds for a beat, then the page closes with `true`
  /// (the order page's rating card turns into its thanks).
  Future<void> _onSubmitted(
    BuildContext context,
    OrderReviewState state,
  ) async {
    Haptics.done();
    await SuccessBeat.hold(context);
    if (!context.mounted) return;
    showHeroSnackBar(
      context,
      'orders.review_thanks'.tr(),
      tone: HeroSnackTone.success,
    );
    context.pop(true);
  }

  static void _signIn(BuildContext context) => context.go(Routes.login);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<OrderReviewCubit>()..load(orderId, initialRating: initialRating),
      child: BlocListener<OrderReviewCubit, OrderReviewState>(
        listenWhen: (previous, current) =>
            !previous.submitted && current.submitted,
        listener: (context, state) => unawaited(_onSubmitted(context, state)),
        child: ScreenFailureListener<OrderReviewCubit, OrderReviewState>(
          onUnauthorized: _signIn,
          // Sending holds the screen; the check shows as the page closes.
          child: CubitBusyOverlay<OrderReviewCubit, OrderReviewState>(
            busyOf: (state) => state.isSubmitting,
            doneOf: (state) => state.submitted,
            failOf: (state) =>
                state.load.failedOnAction && state.load.toldFailure != null,
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
