import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/hero_svg_glyph.dart';
import '../../../../../core/widgets/option_row.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../domain/entities/checkout_draft.dart';
import '../../cubit/checkout_cubit.dart';
import 'checkout_sheet_frame.dart';
import 'checkout_slot_sheet.dart';

/// "Delivery time": ASAP with the address's estimate, Express only when the
/// cart offers it (its real minutes and fee), Schedule only when the address
/// has windows. A tap closes the sheet with the choice; the "Expected" row
/// applies it. Every option waits while the cart runs a server action
/// (express, coupon, points…). Open it with `CheckoutSheetFrame.show(
/// checkout:)`: it reads the page's cubit.
class CheckoutTimingSheet extends StatelessWidget {
  const CheckoutTimingSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final languageCode = context.locale.languageCode;
    final (timing, standardMinutes, hasSlots) = context
        .select<CheckoutCubit, (DeliveryTiming, int?, bool)>(
          (cubit) => (
            cubit.state.draft.timing,
            cubit.state.selection?.etaMinutes,
            cubit.state.hasScheduledSlots,
          ),
        );
    final slotText = context.select<CheckoutCubit, String?>(
      (cubit) => CheckoutSlotSheet.bookedSlotText(languageCode, cubit.state),
    );
    final (offered, expressMinutes, expressFeeKd, busy) = context
        .select<CartCubit, (bool, int?, double, bool)>(
          (cubit) => (
            cubit.state.cart.expressOffered,
            cubit.state.cart.expressEtaMinutes,
            cubit.state.cart.expressSurchargeOfferedKd,
            cubit.state.isBusy,
          ),
        );
    return CheckoutSheetFrame(
      title: 'checkout.timing_sheet_title'.tr(),
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OptionRow(
              leading: const HeroSvgGlyph.mono(
                HeroAssets.sharedClock,
                size: AppSize.s24,
                color: AppColors.primaryText,
              ),
              title: 'checkout.timing_asap'.tr(),
              subtitle: standardMinutes == null
                  ? null
                  : 'checkout.timing_asap_sub'.tr(
                      namedArgs: {'minutes': '$standardMinutes'},
                    ),
              selected: timing == DeliveryTiming.asap,
              enabled: !busy,
              onTap: () => context.pop(DeliveryTiming.asap),
            ),
            if (offered)
              OptionRow(
                leading: const HeroSvgGlyph.art(
                  HeroAssets.checkoutExpressBolt,
                  size: AppSize.s24,
                ),
                title: 'checkout.timing_express'.tr(),
                subtitle: expressMinutes == null
                    ? null
                    : 'checkout.eta_express_note'.plural(
                        expressMinutes,
                        namedArgs: {'amount': Formatters.price(expressFeeKd)},
                      ),
                selected: timing == DeliveryTiming.express,
                enabled: !busy,
                onTap: () => context.pop(DeliveryTiming.express),
              ),
            if (hasSlots)
              OptionRow(
                icon: Icons.event_outlined,
                title: 'checkout.timing_scheduled'.tr(),
                subtitle: slotText ?? 'checkout.timing_scheduled_sub'.tr(),
                selected: timing == DeliveryTiming.scheduled,
                enabled: !busy,
                onTap: () => context.pop(DeliveryTiming.scheduled),
              ),
          ],
        ),
      ),
    );
  }
}
