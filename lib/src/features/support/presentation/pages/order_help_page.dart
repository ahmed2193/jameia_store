import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/domain/entities/order_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/motion/haptics.dart';
import '../../../../core/navigation/screen_failure_listener.dart';
import '../../../../core/navigation/sign_in_flow.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/widgets/cubit_busy_overlay.dart';
import '../../../../core/widgets/hero_title_bar.dart';
import '../../../../core/widgets/reconnect_refresh.dart';
import '../cubit/order_help_cubit.dart';
import '../cubit/order_help_state.dart';
import '../widgets/order_help/order_help_view.dart';

/// "Get help with this order" (`Routes.orderHelp`, `extra`: the order): the
/// customer says what went wrong (and with which items), adds their own
/// words if they like, and the page opens one support ticket about the
/// order (`POST /v1/support/tickets`). The busy overlay holds the screen
/// while it sends; then a success haptic and the thanks. A send that fails
/// keeps every pick and word (offline it says it needs the internet;
/// signed out → sign in).
class OrderHelpPage extends StatelessWidget {
  const OrderHelpPage({super.key, required this.order});

  final OrderEntity order;

  static void _signIn(BuildContext context) => SignInFlow.open(context);

  static void _onSent(BuildContext context, OrderHelpState state) =>
      Haptics.done();

  static void _done(BuildContext context) => context.pop();

  /// Words the ticket in the app's language: the subject names the order
  /// and the issue; without a note of the customer's, the body says the
  /// same and lists the ticked items.
  void _send(BuildContext context) {
    final cubit = context.read<OrderHelpCubit>();
    final request = cubit.state.request;
    final issue = request.issue;
    if (issue == null) return;
    final lc = context.locale.languageCode;
    final number = order.orderNumber;
    final issueName = issue.labelKey.tr();
    final items = [
      for (final line in request.pickedLines(order.lines))
        'support.help_body_item'.tr(
          namedArgs: {'name': line.nameFor(lc), 'count': '${line.quantity}'},
        ),
    ];
    cubit.send(
      orderId: order.id,
      subject: 'support.help_subject'.tr(
        namedArgs: {'number': number, 'issue': issueName},
      ),
      fallbackBody: [
        'support.help_body_issue'.tr(
          namedArgs: {'number': number, 'issue': issueName},
        ),
        if (items.isNotEmpty)
          'support.help_body_items'.tr(namedArgs: {'items': items.join(', ')}),
      ].join('\n'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OrderHelpCubit>()..load(),
      child: BlocListener<OrderHelpCubit, OrderHelpState>(
        listenWhen: (previous, current) => !previous.sent && current.sent,
        listener: _onSent,
        child: ScreenFailureListener<OrderHelpCubit, OrderHelpState>(
          onUnauthorized: _signIn,
          // Busy, and the red mark when the send failed (the draft stays;
          // signed out goes to sign in instead). No done mark: the page
          // stays, and the thanks is its own moment.
          child: CubitBusyOverlay<OrderHelpCubit, OrderHelpState>(
            busyOf: (state) => state.isSending,
            failOf: (state) {
              final failure = state.load.toldFailure;
              return state.load.failedOnAction &&
                  failure != null &&
                  failure is! UnauthorizedFailure;
            },
            child: Scaffold(
              backgroundColor: AppColors.white,
              appBar: HeroTitleBar(title: 'support.get_help_with_order'.tr()),
              body: ContentClamp(
                // Below the provider: the page's own context is above it.
                child: Builder(
                  builder: (context) => ReconnectRefresh(
                    onReconnected: () =>
                        context.read<OrderHelpCubit>().onReconnected(),
                    child: OrderHelpView(
                      order: order,
                      onSend: () => _send(context),
                      onDone: () => _done(context),
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
