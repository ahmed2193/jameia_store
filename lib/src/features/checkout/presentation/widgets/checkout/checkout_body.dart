import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/content_clamp.dart';
import '../../cubit/checkout_cubit.dart';
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
/// and the sticky place-order bar. Each section selects its own slice.
class CheckoutBody extends StatelessWidget {
  const CheckoutBody({super.key});

  @override
  Widget build(BuildContext context) {
    final isPickup = context.select<CheckoutCubit, bool>(
      (cubit) => cubit.state.draft.isPickup,
    );
    return ContentClamp(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s16),
              children: [
                // A Material, not a ColoredBox: the destination row below is
                // tappable, and ListTile paints its ink on the nearest Material
                // ancestor. Over a plain white box that ancestor is the
                // Scaffold, BEHIND the white, so the row answered a tap with
                // nothing at all.
                Material(
                  color: AppColors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CheckoutModeToggle(),
                      if (isPickup)
                        const CheckoutBranchSection()
                      else
                        const CheckoutAddressSection(),
                      const CheckoutTimingSection(),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                const ColoredBox(
                  color: AppColors.white,
                  child: CheckoutPaymentSection(),
                ),
                const SizedBox(height: AppSpacing.s8),
                const ColoredBox(
                  color: AppColors.white,
                  child: CheckoutNotesField(),
                ),
                const SizedBox(height: AppSpacing.s8),
                const ColoredBox(
                  color: AppColors.white,
                  child: CheckoutItemsSection(),
                ),
                const SizedBox(height: AppSpacing.s8),
                const ColoredBox(
                  color: AppColors.white,
                  child: CheckoutSummary(),
                ),
              ],
            ),
          ),
          const CheckoutPlaceOrderBar(),
        ],
      ),
    );
  }
}
