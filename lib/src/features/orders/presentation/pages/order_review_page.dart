import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/navigation/jameia_snack_bar.dart';
import '../../../../core/utils/failure_message.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/signed_out_view.dart';
import '../cubit/order_review_cubit.dart';
import '../cubit/order_review_state.dart';
import '../widgets/review/review_body.dart';

/// Rate the products of a delivered order (`Routes.orderReview`, `extra`:
/// order id) — one `POST /v1/reviews` per rated product. On success the
/// page thanks the customer and closes.
class OrderReviewPage extends StatelessWidget {
  const OrderReviewPage({super.key, required this.orderId});

  final String orderId;

  void _onSubmitted(BuildContext context, OrderReviewState state) {
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
          backgroundColor: AppColors.mediumBackground,
          appBar: AppBar(
            title: Text('orders.review_title'.tr()),
            backgroundColor: AppColors.white,
            surfaceTintColor: AppColors.white,
            elevation: 0,
          ),
          body: BlocBuilder<OrderReviewCubit, OrderReviewState>(
            buildWhen: (previous, current) =>
                previous.status != current.status ||
                previous.order != current.order,
            builder: (context, state) {
              final order = state.order;
              switch (state.status) {
                case OrderReviewStatus.initial:
                case OrderReviewStatus.loading:
                  return const AppLoader();
                case OrderReviewStatus.error:
                  if (state.isSignedOut) {
                    return SignedOutView(
                      message: 'orders.sign_in_required'.tr(),
                    );
                  }
                  return ErrorView(
                    message: state.loadFailure?.localizedMessage,
                    onRetry: () =>
                        context.read<OrderReviewCubit>().load(orderId),
                  );
                case OrderReviewStatus.loaded:
                  return order == null
                      ? const AppLoader()
                      : ReviewBody(order: order);
              }
            },
          ),
        ),
      ),
    );
  }
}
