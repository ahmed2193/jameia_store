import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/domain/entities/delivery_slot_entity.dart';
import '../../../../../core/widgets/hero_list_row.dart';
import '../../../../../core/widgets/hero_svg_glyph.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../domain/entities/checkout_draft.dart';
import '../../../domain/entities/checkout_eta.dart';
import '../../cubit/checkout_cart_facts_of.dart';
import '../../cubit/checkout_cubit.dart';
import 'checkout_eta_badge.dart';
import 'checkout_eta_minutes.dart';
import 'checkout_sheet_frame.dart';
import 'checkout_slot_sheet.dart';
import 'checkout_timing_sheet.dart';

/// "Expected ⚡ 15 min ›": the flat Hero row under the destination. The
/// clock icon, "Expected", the express mark (only while express is on the
/// order) and the estimate — minutes, the booked window, or why there is
/// none (closed branch / no capacity). A tap opens the timing sheet (ASAP,
/// Express when the cart offers it, Schedule when the address has windows).
/// Pickup reads "Ready for pickup · N min" — or "Pickup" with why nothing
/// will be ready (closed branch / no capacity) — and takes no tap.
class CheckoutEtaRow extends StatelessWidget {
  const CheckoutEtaRow({super.key});

  Future<void> _open(BuildContext context) async {
    final picked = await CheckoutSheetFrame.show<DeliveryTiming>(
      context,
      checkout: context.read<CheckoutCubit>(),
      builder: (_) => const CheckoutTimingSheet(),
    );
    if (picked == null || !context.mounted) return; // dismissed
    await _pick(context, picked);
  }

  /// Express is a cart flag the server owns (`POST /v1/cart/express`), so
  /// the draft moves first and goes back when the server refuses — timing
  /// AND the booked window. Schedule opens the slot sheet (again, with the
  /// booked window marked, when it is already scheduled); a dismissed slot
  /// sheet changes nothing.
  Future<void> _pick(BuildContext context, DeliveryTiming timing) async {
    final checkout = context.read<CheckoutCubit>();
    final cart = context.read<CartCubit>();
    final previousTiming = checkout.state.draft.timing;
    final previousSlot = checkout.state.draft.slot;
    if (timing == DeliveryTiming.scheduled) {
      final booked = await CheckoutSheetFrame.show<DeliverySlotEntity>(
        context,
        checkout: checkout,
        large: true,
        builder: (_) => CheckoutSlotSheet(preselected: previousSlot),
      );
      if (booked == null) return; // the sheet books the window itself
    } else {
      if (timing == previousTiming) return;
      checkout.setTiming(timing);
    }
    final wantsExpress = timing == DeliveryTiming.express;
    if (cart.state.cart.expressSelected == wantsExpress) return;
    if (await cart.setExpress(enabled: wantsExpress)) return;
    // The server refused the surcharge change: put the choice back.
    if (previousTiming == DeliveryTiming.scheduled && previousSlot != null) {
      checkout.setSlot(previousSlot);
    } else {
      checkout.setTiming(previousTiming);
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = context.locale.languageCode;
    final facts = context.select<CartCubit, CheckoutEtaCartFacts>(
      (cubit) => cubit.state.etaFacts,
    );
    final (eta, isPickup) = context.select<CheckoutCubit, (CheckoutEta, bool)>(
      (cubit) => (cubit.state.etaWith(facts), cubit.state.draft.isPickup),
    );
    final slotText = context.select<CheckoutCubit, String?>(
      (cubit) => CheckoutSlotSheet.bookedSlotText(languageCode, cubit.state),
    );
    final pickupBlocked =
        eta.kind == CheckoutEtaKind.branchClosed ||
        eta.kind == CheckoutEtaKind.noCapacity;
    return MergeSemantics(
      child: InkWell(
        onTap: isPickup ? null : () => _open(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: HeroListRow.denseMinHeight,
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: HeroListRow.denseInset,
              vertical: AppSpacing.s12,
            ),
            child: Row(
              children: [
                const HeroSvgGlyph.mono(
                  HeroAssets.sharedClock,
                  size: HeroListRow.denseLeadSize,
                  color: AppColors.primaryText,
                ),
                const SizedBox(width: HeroListRow.denseGap),
                Text(
                  !isPickup
                      ? 'checkout.eta_expected'.tr()
                      : pickupBlocked
                      ? 'checkout.receipt_pickup'.tr()
                      : 'checkout.eta_pickup'.tr(),
                  style: AppTextStyles.label.copyWith(
                    fontWeight: AppTextStyles.bold,
                  ),
                ),
                CheckoutEtaBadge(
                  express: eta.kind == CheckoutEtaKind.express,
                  bolt: eta.expressFaster,
                ),
                const SizedBox(width: AppSpacing.s6),
                Expanded(
                  child: CheckoutEtaMinutes(
                    eta: eta,
                    isPickup: isPickup,
                    slotText: slotText,
                  ),
                ),
                if (!isPickup) ...[
                  const SizedBox(width: AppSpacing.s4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: HeroListRow.denseLeadSize,
                    color: AppColors.primaryText,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
