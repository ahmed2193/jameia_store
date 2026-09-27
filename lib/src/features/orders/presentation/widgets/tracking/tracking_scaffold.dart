import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/navigation/screen_failure_listener.dart';
import '../../../../../core/responsive/content_clamp.dart';
import '../../../../../core/widgets/hero_title_bar.dart';
import '../../cubit/order_tracking_cubit.dart';
import '../../cubit/order_tracking_state.dart';
import '../order_detail_state_switcher.dart';
import 'tracking_body.dart';

/// The tracking page's frame: the cancelled / failure listeners, the title
/// bar and the state swap. Built `const` by `OrderTrackingView`, whose route
/// dependency fires on every push / pop over the page (the invoice, the
/// cancel sheet): the identical widget is skipped, so none of this rebuilds.
class TrackingScaffold extends StatelessWidget {
  const TrackingScaffold({super.key});

  void _onCancelled(BuildContext context, OrderTrackingState state) =>
      showHeroSnackBar(context, 'orders.cancelled_done'.tr());

  static void _signIn(BuildContext context) => context.go(Routes.login);

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderTrackingCubit, OrderTrackingState>(
      listenWhen: (previous, current) =>
          !previous.cancelled && current.cancelled,
      listener: _onCancelled,
      child: ScreenFailureListener<OrderTrackingCubit, OrderTrackingState>(
        onUnauthorized: _signIn,
        child: Scaffold(
          backgroundColor: AppColors.white,
          appBar: HeroTitleBar(title: 'orders.tracking_title'.tr()),
          body: ContentClamp(
            child: BlocBuilder<OrderTrackingCubit, OrderTrackingState>(
              buildWhen: (previous, current) =>
                  current.load.screenChangedFrom(previous.load) ||
                  previous.order != current.order,
              builder: (context, state) {
                final order = state.order;
                // Once there is an order it stays on screen across every poll
                // (and a failed poll): the body updates in place.
                return OrderDetailStateSwitcher(
                  content: order == null ? null : TrackingBody(order: order),
                  failure: state.loadFailure,
                  isSignedOut: state.isSignedOut,
                  errorMessage: state.isNotFound
                      ? 'orders.not_found'.tr()
                      : null,
                  onRetry: () => context.read<OrderTrackingCubit>().refresh(),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
