import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/navigation/jameia_snack_bar.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/connectivity_scope.dart';
import '../../../../../core/widgets/jameia_submit_button.dart';
import '../../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../domain/entities/checkout_block_reason.dart';
import '../../cubit/checkout_cart_facts_of.dart';
import '../../cubit/checkout_cubit.dart';
import '../../cubit/checkout_state.dart';
import 'checkout_bar_fact_text.dart';
import 'checkout_ui_controller.dart';

/// "Place order": the green sticker pill at the end of the bar, 140 × 48.
/// It fires once ([CheckoutCubit.placeOrder] with the cart's facts) and only
/// when nothing is in flight, the cart has settled and
/// [CheckoutBlockReason.resolve] names no reason. Loading shows the loader,
/// a placed order the check.
///
/// A tap on the disabled pill says why: a missing destination or window
/// scrolls to its row and shakes it, a line issue opens the items sheet,
/// maintenance scrolls to the banner at the top, anything else is a snack —
/// each with a warning haptic. While the cart is only settling (no reason)
/// the tap does nothing: the total already says "Updating…".
///
/// An order is never queued: while the app reads as offline the tap runs a
/// live check first, and when the connection is still gone it nudges the
/// banner and says so instead of sending (or keeping) the order.
///
/// It is also the anchor the savings hint rides on
/// ([CheckoutUiController.barLink]).
class CheckoutPlaceButton extends StatelessWidget {
  const CheckoutPlaceButton({super.key});

  static const double width = AppSize.s140;
  static const double height = AppSize.s48;

  Future<void> _place(BuildContext context) async {
    if (ConnectivityScope.readIsOffline(context) &&
        !await ConnectivityScope.confirmOnline(context)) {
      if (!context.mounted) return;
      ConnectivityScope.nudge(context);
      showJameiaSnackBar(context, 'connectivity.action_needs_internet'.tr());
      return;
    }
    if (!context.mounted) return;
    final walletFils = context
        .read<AuthSessionCubit>()
        .state
        .customer
        ?.walletFils;
    context.read<CheckoutCubit>().placeOrder(
      context.read<CartCubit>().state.checkoutFacts(walletFils: walletFils),
    );
  }

  void _onBlocked(BuildContext context, CheckoutBlockReason? reason) {
    if (reason == null || reason == CheckoutBlockReason.empty) return;
    Haptics.warning();
    final ui = context.read<CheckoutUiController>();
    switch (reason) {
      case CheckoutBlockReason.destination:
        ui.signalBlocked(reason);
        _reveal(context, ui.destinationAnchor);
      case CheckoutBlockReason.slot:
        ui.signalBlocked(reason);
        _reveal(context, ui.timingAnchor);
      case CheckoutBlockReason.lineIssue:
        ui.requestItems();
      case CheckoutBlockReason.maintenance:
        _scrollToTop(context);
      case CheckoutBlockReason.notesTooLong ||
          CheckoutBlockReason.offline ||
          CheckoutBlockReason.empty ||
          CheckoutBlockReason.minOrder ||
          CheckoutBlockReason.branchClosed ||
          CheckoutBlockReason.capacity ||
          CheckoutBlockReason.payment:
        showJameiaSnackBar(
          context,
          CheckoutBarFactText.reasonText(
            reason,
            shortfallKd: context
                .read<CartCubit>()
                .state
                .cart
                .totals
                .shortfallKd,
            pickup: context.read<CheckoutCubit>().state.draft.isPickup,
          ),
        );
    }
  }

  /// Brings the row behind [anchor] back into view (the rows sit at the top
  /// of the page, so the scroll only ever goes back up). A row scrolled so
  /// far away that it is no longer built is reached through the top.
  void _reveal(BuildContext context, GlobalKey anchor) {
    final row = anchor.currentContext;
    if (row == null) {
      _scrollToTop(context);
      return;
    }
    Scrollable.ensureVisible(
      row,
      duration: MotionGuard.duration(context, AppMotion.medium),
      curve: AppMotion.signature,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
    );
  }

  /// The page's scroll view is the route's primary one.
  void _scrollToTop(BuildContext context) {
    final controller = PrimaryScrollController.maybeOf(context);
    if (controller == null || !controller.hasClients) return;
    final duration = MotionGuard.duration(context, AppMotion.medium);
    if (duration == Duration.zero) {
      controller.jumpTo(0);
      return;
    }
    controller.animateTo(0, duration: duration, curve: AppMotion.signature);
  }

  @override
  Widget build(BuildContext context) {
    final checkout = context.read<CheckoutCubit>();
    final (canPlace, placing, placed, _) = context
        .select<CheckoutCubit, (bool, bool, bool, Object)>(
          (cubit) => (
            cubit.state.canPlace,
            cubit.state.isPlacing,
            cubit.state.status == CheckoutStatus.placed,
            cubit.state.blockInputs,
          ),
        );
    final walletFils = context.select<AuthSessionCubit, int?>(
      (cubit) => cubit.state.customer?.walletFils,
    );
    final (settled, reason) = context
        .select<CartCubit, (bool, CheckoutBlockReason?)>((cubit) {
          final facts = cubit.state.checkoutFacts(walletFils: walletFils);
          return (facts.settled, checkout.state.reasonFor(facts));
        });
    return CompositedTransformTarget(
      link: context.read<CheckoutUiController>().barLink,
      child: SizedBox(
        width: width,
        child: JameiaSubmitButton(
          label: placing
              ? 'checkout.placing'.tr()
              : 'checkout.place_order'.tr(),
          sticker: true,
          height: height,
          loading: placing,
          success: placed,
          successLabel: 'checkout.order_placed'.tr(),
          enabled: canPlace && settled && reason == null,
          onPressed: () => unawaited(_place(context)),
          onBlocked: () => _onBlocked(context, reason),
        ),
      ),
    );
  }
}
