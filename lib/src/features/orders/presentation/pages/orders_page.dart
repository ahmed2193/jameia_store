import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/navigation/jameia_snack_bar.dart';
import '../../../../core/utils/failure_message.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/orders_skeleton.dart';
import '../../../../core/widgets/signed_out_view.dart';
import '../cubit/orders_cubit.dart';
import '../cubit/orders_state.dart';
import '../widgets/orders_list/orders_list.dart';

/// The customer's orders from `GET /v1/orders`: every order in one list,
/// newest first, each row carrying its own status. Signed out → sign-in
/// prompt.
///
/// As a tab this page lives inside the shell's [IndexedStack], so it is built
/// once and never disposed: [active] is how the shell says it is the tab on
/// screen. Coming back to it re-reads the list, because an order placed,
/// cancelled or reviewed on another screen happened behind its back.
class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key, this.active = true, this.embedded = false});

  /// `false` while another tab is showing. A page pushed as its own route
  /// is always active.
  final bool active;

  /// Inside the Cart tab as its "order history" view: the tab draws the
  /// header, so the page drops its own app bar.
  final bool embedded;

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late final OrdersCubit _cubit = sl<OrdersCubit>()..load();

  @override
  void didUpdateWidget(covariant OrdersPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only the step back ONTO the tab reloads; leaving it costs nothing.
    if (widget.active && !oldWidget.active) unawaited(_cubit.refresh());
  }

  @override
  void dispose() {
    unawaited(_cubit.close());
    super.dispose();
  }

  void _onFailure(BuildContext context, OrdersState state) {
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
    return BlocProvider<OrdersCubit>.value(
      value: _cubit,
      child: BlocListener<OrdersCubit, OrdersState>(
        listenWhen: (previous, current) =>
            current.failure != null && previous != current,
        listener: _onFailure,
        child: Scaffold(
          backgroundColor: AppColors.mediumBackground,
          appBar: widget.embedded
              ? null
              : AppBar(
                  title: Text(
                    'orders.title'.tr(),
                    style: AppTextStyles.displaySmall.copyWith(
                      fontWeight: AppTextStyles.medium,
                    ),
                  ),
                  backgroundColor: AppColors.white,
                  surfaceTintColor: AppColors.white,
                  elevation: 0,
                  centerTitle: false,
                ),
          body: BlocBuilder<OrdersCubit, OrdersState>(
            buildWhen: (previous, current) =>
                previous.status != current.status ||
                previous.loadFailure != current.loadFailure,
            builder: (context, state) {
              switch (state.status) {
                case OrdersStatus.initial:
                case OrdersStatus.loading:
                  return const OrdersSkeleton();
                case OrdersStatus.error:
                  if (state.isSignedOut) {
                    return SignedOutView(
                      message: 'orders.sign_in_required'.tr(),
                    );
                  }
                  return ErrorView(
                    message: state.loadFailure?.localizedMessage,
                    onRetry: context.read<OrdersCubit>().load,
                  );
                case OrdersStatus.loaded:
                  return const OrdersList();
              }
            },
          ),
        ),
      ),
    );
  }
}
