import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/motion/second_clock_scope.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/navigation/screen_failure_listener.dart';
import '../../../../../core/responsive/content_clamp.dart';
import '../../cubit/order_tracking_cubit.dart';
import '../../cubit/order_tracking_state.dart';
import '../order_detail_state_switcher.dart';
import 'tracking_body.dart';
import 'tracking_bottom_bar.dart';
import 'tracking_skeleton.dart';
import 'tracking_title_bar.dart';

/// The order page's frame: the cancelled / failure listeners, the title bar
/// (the order number, "Help"), the state swap (the skeleton while the first
/// read is on the way), the minute clock the time line counts down on, and
/// the "Reorder" foot. Built `const` by `OrderTrackingView`, whose route
/// dependency fires on every push / pop over the page (the invoice, the
/// cancel sheet): the identical widget is skipped, so none of this rebuilds.
class TrackingScaffold extends StatelessWidget {
  const TrackingScaffold({super.key});

  /// The time line moves once a minute (the clock rests while the page is
  /// covered or in the background).
  static const Duration _minute = Duration(minutes: 1);

  void _onCancelled(BuildContext context, OrderTrackingState state) =>
      showHeroSnackBar(
        context,
        'orders.cancelled_done'.tr(),
        tone: HeroSnackTone.success,
      );

  static void _signIn(BuildContext context) => SignInFlow.open(context);

  /// Help about THIS order once it is on screen (the support ticket form);
  /// before that (still loading, or it could not load) the help hub.
  static void _openHelp(BuildContext context) {
    final order = context.read<OrderTrackingCubit>().state.order;
    if (order == null) {
      context.push(Routes.customerService);
    } else {
      context.push(Routes.orderHelp, extra: order);
    }
  }

  static void _back(BuildContext context) =>
      context.canPop() ? context.pop() : context.go(Routes.orders);

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
          appBar: TrackingTitleBar(onHelp: () => _openHelp(context)),
          bottomNavigationBar: const TrackingBottomBar(),
          body: ContentClamp(
            child: SecondClockScope(
              period: _minute,
              child: BlocBuilder<OrderTrackingCubit, OrderTrackingState>(
                buildWhen: (previous, current) =>
                    current.load.screenChangedFrom(previous.load) ||
                    previous.order != current.order,
                builder: (context, state) {
                  final order = state.order;
                  // Once there is an order it stays on screen across every
                  // poll (and a failed poll): the body updates in place.
                  return OrderDetailStateSwitcher(
                    content: order == null
                        ? null
                        : TrackingBody(
                            order: order,
                            onHelp: () => _openHelp(context),
                          ),
                    failure: state.loadFailure,
                    isSignedOut: state.isSignedOut,
                    notFound: state.isNotFound,
                    onBack: () => _back(context),
                    loading: const TrackingSkeleton(),
                    onRetry: () => context.read<OrderTrackingCubit>().refresh(),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
