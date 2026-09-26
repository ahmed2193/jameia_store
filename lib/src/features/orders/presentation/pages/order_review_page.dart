import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/motion/haptics.dart';
import '../../../../core/navigation/jameia_snack_bar.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/utils/failure_message.dart';
import '../../../../core/widgets/jameia_title_bar.dart';
import '../cubit/order_review_cubit.dart';
import '../cubit/order_review_state.dart';
import '../widgets/order_detail_state_switcher.dart';
import '../widgets/review/review_body.dart';

/// Rate the products of a delivered order (`Routes.orderReview`, `extra`:
/// order id) — one `POST /v1/reviews` per rated product. On success the
/// page thanks the customer (a success haptic, the submit pill's check) and
/// closes.
class OrderReviewPage extends StatelessWidget {
  const OrderReviewPage({super.key, required this.orderId});

  final String orderId;

  void _onSubmitted(BuildContext context, OrderReviewState state) {
    Haptics.success();
    showJameiaSnackBar(context, 'orders.review_thanks'.tr());
    context.pop();
  }

  void _onFailure(BuildContext context, OrderReviewState state) {
    final failure = state.failure;
    if (failure == null || state.loadFailure != null) return;
    if (state.isSignedOut) {
      context.go(Routes.login);
      return;
    }
    showJameiaSnackBar(context, failure.localizedMessage);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OrderReviewCubit>()..load(orderId),
      child: MultiBlocListener(
        listeners: [
          BlocListener<OrderReviewCubit, OrderReviewState>(
            listenWhen: (previous, current) =>
                !previous.submitted && current.submitted,
            listener: _onSubmitted,
          ),
          BlocListener<OrderReviewCubit, OrderReviewState>(
            listenWhen: (previous, current) =>
                current.failure != null && previous != current,
            listener: _onFailure,
          ),
        ],
        child: Scaffold(
          backgroundColor: AppColors.white,
          appBar: JameiaTitleBar(title: 'orders.review_title'.tr()),
          body: ContentClamp(
            child: BlocBuilder<OrderReviewCubit, OrderReviewState>(
              buildWhen: (previous, current) =>
                  previous.status != current.status ||
                  previous.order != current.order,
              builder: (context, state) {
                final order = state.order;
                return OrderDetailStateSwitcher(
                  content:
                      state.status == OrderReviewStatus.loaded && order != null
                      ? ReviewBody(order: order)
                      : null,
                  failed: state.status == OrderReviewStatus.error,
                  isSignedOut: state.isSignedOut,
                  errorMessage: state.loadFailure?.localizedMessage,
                  onRetry: () => context.read<OrderReviewCubit>().load(orderId),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
