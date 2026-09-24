import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/utils/failure_message.dart';
import '../../../../../core/widgets/app_loader.dart';
import '../../../../../core/widgets/error_view.dart';
import '../../../../../core/widgets/signed_out_view.dart';
import '../../cubit/order_tracking_cubit.dart';
import '../../cubit/order_tracking_state.dart';
import 'tracking_body.dart';

/// Owns the visibility of the tracking page: it subscribes to the router's
/// [routeObserver] (covered by another page) and to the app lifecycle
/// (backgrounded), and tells the cubit when to poll.
class OrderTrackingView extends StatefulWidget {
  const OrderTrackingView({super.key});

  @override
  State<OrderTrackingView> createState() => _OrderTrackingViewState();
}

class _OrderTrackingViewState extends State<OrderTrackingView>
    with RouteAware, WidgetsBindingObserver {
  bool _onTop = true;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is ModalRoute<void>) routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didPushNext() => _setVisible(onTop: false);

  @override
  void didPopNext() => _setVisible(onTop: true);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      _setVisible(foreground: state == AppLifecycleState.resumed);

  void _setVisible({bool? onTop, bool? foreground}) {
    _onTop = onTop ?? _onTop;
    _foreground = foreground ?? _foreground;
    if (!mounted) return;
    context.read<OrderTrackingCubit>().setVisible(_onTop && _foreground);
  }

  void _onCancelled(BuildContext context, OrderTrackingState state) =>
      showJameiaSnackBar(context, 'orders.cancelled_done'.tr());

  void _onFailure(BuildContext context, OrderTrackingState state) {
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
    return MultiBlocListener(
      listeners: [
        BlocListener<OrderTrackingCubit, OrderTrackingState>(
          listenWhen: (previous, current) =>
              !previous.cancelled && current.cancelled,
          listener: _onCancelled,
        ),
        BlocListener<OrderTrackingCubit, OrderTrackingState>(
          listenWhen: (previous, current) =>
              current.failure != null && previous != current,
          listener: _onFailure,
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.mediumBackground,
        appBar: AppBar(
          title: Text('orders.tracking_title'.tr()),
          backgroundColor: AppColors.white,
          surfaceTintColor: AppColors.white,
          elevation: 0,
        ),
        body: BlocBuilder<OrderTrackingCubit, OrderTrackingState>(
          buildWhen: (previous, current) =>
              previous.status != current.status ||
              previous.order != current.order ||
              previous.loadFailure != current.loadFailure,
          builder: (context, state) {
            final order = state.order;
            if (order != null) return TrackingBody(order: order);
            switch (state.status) {
              case OrderTrackingStatus.initial:
              case OrderTrackingStatus.loading:
                return const AppLoader();
              case OrderTrackingStatus.error:
                if (state.isSignedOut) {
                  return SignedOutView(message: 'orders.sign_in_required'.tr());
                }
                return ErrorView(
                  message: state.isNotFound
                      ? 'orders.not_found'.tr()
                      : state.loadFailure?.localizedMessage,
                  onRetry: context.read<OrderTrackingCubit>().refresh,
                );
              case OrderTrackingStatus.loaded:
                return const AppLoader();
            }
          },
        ),
      ),
    );
  }
}
