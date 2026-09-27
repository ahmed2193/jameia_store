import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/domain/entities/screen_load.dart';
import '../../../../core/motion/fade_through_switcher.dart';
import '../../../../core/navigation/screen_failure_listener.dart';
import '../../../../core/widgets/cubit_busy_overlay.dart';
import '../../../../core/widgets/failure_view.dart';
import '../../../../core/widgets/hero_state_view.dart';
import '../../../../core/widgets/hero_title_bar.dart';
import '../../../../core/widgets/orders_skeleton.dart';
import '../../../../core/widgets/reconnect_refresh.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/cubit/cart_state.dart';
import '../cubit/orders_cubit.dart';
import '../cubit/orders_state.dart';
import '../widgets/orders_list/orders_list.dart';

/// The customer's orders from `GET /v1/orders`: every order in one list,
/// newest first, each row carrying its own status. The list saved on the
/// device paints at once (offline too, under the "Updated … ago" note).
/// Signed out → sign-in prompt; offline with nothing saved → "No
/// connection", which loads by itself when the connection returns.
///
/// As a tab this page lives inside the shell's [IndexedStack], so it is built
/// once and never disposed: [active] is how the shell says it is the tab on
/// screen. Coming back to it re-reads the list (when online), because an
/// order placed, cancelled or reviewed on another screen happened behind its
/// back (offline that read fails quietly, and the reconnect refreshes the
/// list it left stale).
///
/// The states (skeleton, list, error, signed out) fade through one another,
/// keyed by the status bucket only: a refresh keeps `loaded`, so the list is
/// never torn down or faded again while it is on screen.
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

  static void _signIn(BuildContext context) => context.go(Routes.login);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrdersCubit>.value(
      value: _cubit,
      child: ScreenFailureListener<OrdersCubit, OrdersState>(
        onUnauthorized: _signIn,
        // A cancel and a reorder each hold the screen until the server
        // answers.
        child: CubitBusyOverlay<OrdersCubit, OrdersState>(
          busyOf: (state) => state.cancellingId != null,
          child: CubitBusyOverlay<CartCubit, CartState>(
            busyOf: (state) => state.busyAction == CartAction.addItems,
            child: Scaffold(
              backgroundColor: AppColors.white,
              // The page has no text field; only the cancel sheet above it opens
              // the keyboard, and the list behind the barrier need not re-lay
              // out on every frame of that.
              resizeToAvoidBottomInset: false,
              appBar: widget.embedded
                  ? null
                  : HeroTitleBar(title: 'orders.title'.tr()),
              // In the Cart tab the page sits in the shell's IndexedStack, which
              // keeps hidden tabs animating: a hidden history ticks nothing (the
              // skeleton shimmer, the first-page cascade). A pushed page has no
              // such scope, so this stays on there.
              body: TickerMode(
                enabled: Visibility.of(context),
                child: ReconnectRefresh(
                  onReconnected: () => _cubit.onReconnected(),
                  child: BlocBuilder<OrdersCubit, OrdersState>(
                    buildWhen: (previous, current) =>
                        current.load.screenChangedFrom(previous.load),
                    builder: (context, state) {
                      final bucket = switch (state.status) {
                        LoadPhase.initial ||
                        LoadPhase.loading => LoadPhase.loading,
                        final status => status,
                      };
                      return FadeThroughSwitcher(
                        stateKey: bucket,
                        alignment: AlignmentDirectional.topCenter,
                        child: switch (state.status) {
                          LoadPhase.initial ||
                          LoadPhase.loading => const OrdersSkeleton(),
                          LoadPhase.error when state.isSignedOut =>
                            HeroStateView.signedOut(
                              message: 'orders.sign_in_required'.tr(),
                            ),
                          LoadPhase.error => FailureView(
                            failure: state.loadFailure,
                            onRetry: _cubit.load,
                            errorBuilder: (message) => HeroStateView.error(
                              message: message,
                              onRetry: _cubit.load,
                            ),
                          ),
                          LoadPhase.loaded => const OrdersList(),
                        },
                      );
                    },
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
