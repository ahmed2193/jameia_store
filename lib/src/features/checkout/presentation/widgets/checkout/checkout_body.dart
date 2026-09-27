import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/content_clamp.dart';
import '../../cubit/checkout_cubit.dart';
import '../../cubit/checkout_state.dart';
import 'checkout_band.dart';
import 'checkout_info_section.dart';
import 'checkout_options_section.dart';
import 'checkout_order_summary.dart';
import 'checkout_payment_section.dart';
import 'checkout_place_order_bar.dart';
import 'checkout_rail_section.dart';
import 'checkout_receipt.dart';
import 'checkout_savings_hint.dart';
import 'checkout_savings_section.dart';
import 'checkout_ui_controller.dart';
import 'checkout_where_when_block.dart';

/// The loaded checkout, in Hero's order: where and when (Block A), the
/// deals rail, then order summary + instant savings + order totals in one
/// block, payment, additional options and "good to know" — white blocks on
/// grey bands in ONE scroll view — over the pinned place-order bar, with
/// the savings hint riding on the bar's button.
///
/// Each section selects its own slice, so this body builds once: it only
/// watches whether the order was placed. The page's [CheckoutUiController]
/// (provided with the page) carries the signals between them.
///
/// Any scroll the customer makes (a drag on the page or on the rail)
/// dismisses the savings hint for the visit. Placing the order resets the
/// cart while this page is still on screen under the tracking page's
/// entrance, so the scroll view's motion freezes from then on: nothing
/// resizes, folds or rolls behind the transition.
class CheckoutBody extends StatelessWidget {
  const CheckoutBody({super.key});

  @override
  Widget build(BuildContext context) {
    final placed = context.select<CheckoutCubit, bool>(
      (cubit) => cubit.state.status == CheckoutStatus.placed,
    );
    final ui = context.read<CheckoutUiController>();
    return ContentClamp(
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: TickerMode(
                  enabled: !placed,
                  child: NotificationListener<UserScrollNotification>(
                    onNotification: (notification) {
                      if (notification.direction != ScrollDirection.idle) {
                        ui.hintDismissed.value = true;
                      }
                      return false;
                    },
                    // The route's primary scroll view: a blocked tap on
                    // "Place order" scrolls it back to the top.
                    child: const CustomScrollView(
                      primary: true,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      slivers: [
                        SliverToBoxAdapter(child: CheckoutWhereWhenBlock()),
                        SliverToBoxAdapter(child: CheckoutRailSection()),
                        SliverToBoxAdapter(
                          child: CheckoutBand(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                CheckoutOrderSummary(),
                                CheckoutSavingsSection(),
                                CheckoutReceipt(),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: CheckoutBand(child: CheckoutPaymentSection()),
                        ),
                        SliverToBoxAdapter(
                          child: CheckoutBand(child: CheckoutOptionsSection()),
                        ),
                        SliverToBoxAdapter(
                          child: CheckoutBand(child: CheckoutInfoSection()),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(height: AppSpacing.s24),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const CheckoutPlaceOrderBar(),
            ],
          ),
          const CheckoutSavingsHint(),
        ],
      ),
    );
  }
}
