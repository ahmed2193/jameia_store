import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/size_fade_switcher.dart';
import '../../../../../core/responsive/content_clamp.dart';
import '../../cubit/checkout_cubit.dart';
import '../../cubit/checkout_state.dart';
import 'checkout_address_section.dart';
import 'checkout_branch_section.dart';
import 'checkout_items_section.dart';
import 'checkout_mode_toggle.dart';
import 'checkout_notes_field.dart';
import 'checkout_payment_section.dart';
import 'checkout_place_order_bar.dart';
import 'checkout_summary.dart';
import 'checkout_timing_section.dart';

/// The loaded checkout: destination, timing, payment, notes, items, totals
/// and the sticky place-order bar. Each section selects its own slice; the
/// items build lazily. The rows paint their ink on the card Materials they
/// sit on, over the white Scaffold.
///
/// Placing the order resets the cart while this page is still on screen
/// under the tracking page's entrance, so the scroll view's motion freezes
/// from then on: nothing resizes, folds or rolls behind the transition.
class CheckoutBody extends StatelessWidget {
  const CheckoutBody({super.key});

  @override
  Widget build(BuildContext context) {
    final isPickup = context.select<CheckoutCubit, bool>(
      (cubit) => cubit.state.draft.isPickup,
    );
    final placed = context.select<CheckoutCubit, bool>(
      (cubit) => cubit.state.status == CheckoutStatus.placed,
    );
    final destination = isPickup
        ? const CheckoutBranchSection()
        : const CheckoutAddressSection();
    return ContentClamp(
      child: Column(
        children: [
          Expanded(
            child: TickerMode(
              enabled: !placed,
              child: CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  const SliverToBoxAdapter(child: CheckoutModeToggle()),
                  SliverToBoxAdapter(
                    // The address and the branch section swap in place: the
                    // height eases to the new one while the old fades out.
                    // Reduced motion swaps at once — and skips the switcher,
                    // whose AnimatedSize trips a layout assertion at a zero
                    // duration.
                    child: MotionGuard.reduced(context)
                        ? destination
                        : SizeFadeSwitcher(
                            stateKey: isPickup,
                            child: destination,
                          ),
                  ),
                  const SliverToBoxAdapter(child: CheckoutTimingSection()),
                  const SliverToBoxAdapter(child: CheckoutPaymentSection()),
                  const SliverToBoxAdapter(child: CheckoutNotesField()),
                  const CheckoutItemsSection(),
                  const SliverPadding(
                    padding: EdgeInsetsDirectional.only(
                      bottom: AppSpacing.section,
                    ),
                    sliver: SliverToBoxAdapter(child: CheckoutSummary()),
                  ),
                ],
              ),
            ),
          ),
          const CheckoutPlaceOrderBar(),
        ],
      ),
    );
  }
}
