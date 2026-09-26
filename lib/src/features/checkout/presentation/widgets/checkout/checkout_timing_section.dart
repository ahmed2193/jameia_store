import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/domain/entities/delivery_slot_entity.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/jameia_list_card.dart';
import '../../../../../core/widgets/jameia_sheet_header.dart';
import '../../../../../core/widgets/option_row.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../domain/entities/checkout_draft.dart';
import '../../cubit/checkout_cubit.dart';
import 'checkout_section.dart';
import 'checkout_slot_sheet.dart';

/// ASAP / express / scheduled. Express is a cart flag on the server
/// (`POST /v1/cart/express`), so choosing it goes through the cart cubit;
/// scheduled opens the slot sheet. Pickup has no timing: the section folds
/// away (and opens again) instead of vanishing.
class CheckoutTimingSection extends StatelessWidget {
  const CheckoutTimingSection({super.key});

  /// Express is a cart flag the server owns, so the draft only moves once the
  /// cart took the change; a dismissed slot sheet changes nothing.
  Future<void> _pick(BuildContext context, DeliveryTiming timing) async {
    final checkout = context.read<CheckoutCubit>();
    final cart = context.read<CartCubit>();
    final previous = checkout.state.draft.timing;
    if (timing == previous) return;
    if (timing == DeliveryTiming.scheduled) {
      await showJameiaBottomSheet<void>(
        context,
        large: true,
        isScrollControlled: true,
        backgroundColor: AppColors.white,
        shape: JameiaSheetHeader.shape,
        builder: (_) => BlocProvider.value(
          value: checkout,
          child: const CheckoutSlotSheet(),
        ),
      );
      // The sheet records the slot; dismissed without one, nothing moved.
      if (checkout.state.draft.timing != DeliveryTiming.scheduled) return;
    } else {
      checkout.setTiming(timing);
    }
    final wantsExpress = timing == DeliveryTiming.express;
    if (cart.state.cart.expressSelected == wantsExpress) return;
    if (!await cart.setExpress(enabled: wantsExpress)) {
      checkout.setTiming(previous); // the server refused the surcharge change
    }
  }

  @override
  Widget build(BuildContext context) {
    // The three draft fields this section shows, as values: a notes
    // keystroke writes a new draft but rebuilds nothing here.
    final (timing, slot, isPickup) = context
        .select<CheckoutCubit, (DeliveryTiming, DeliverySlotEntity?, bool)>(
          (cubit) => (
            cubit.state.draft.timing,
            cubit.state.draft.slot,
            cubit.state.draft.isPickup,
          ),
        );
    final eta = context.select<CheckoutCubit, int?>(
      (cubit) => cubit.state.selection?.etaMinutes,
    );
    final hasSlots = context.select<CheckoutCubit, bool>(
      (cubit) => cubit.state.hasScheduledSlots,
    );
    final (expressOffered, expressMinutes, expressSurchargeKd) = context
        .select<CartCubit, (bool, int?, double)>(
          (cubit) => (
            cubit.state.cart.expressOffered,
            cubit.state.cart.expressEtaMinutes,
            cubit.state.cart.expressSurchargeOfferedKd,
          ),
        );
    return CollapseReveal(
      visible: !isPickup,
      child: CheckoutSection(
        title: 'checkout.timing_title'.tr(),
        child: JameiaListCard(
          children: [
            OptionRow(
              icon: Icons.schedule_rounded,
              title: 'checkout.timing_asap'.tr(),
              subtitle: eta == null
                  ? null
                  : 'checkout.timing_asap_sub'.tr(
                      namedArgs: {'minutes': '$eta'},
                    ),
              selected: timing == DeliveryTiming.asap,
              onTap: () => _pick(context, DeliveryTiming.asap),
            ),
            if (expressOffered)
              OptionRow(
                icon: Icons.bolt_rounded,
                title: 'checkout.timing_express'.tr(),
                subtitle: 'checkout.timing_express_sub'.tr(
                  namedArgs: {
                    'minutes': '${expressMinutes ?? 0}',
                    'amount': Formatters.price(expressSurchargeKd),
                  },
                ),
                selected: timing == DeliveryTiming.express,
                onTap: () => _pick(context, DeliveryTiming.express),
              ),
            if (hasSlots)
              OptionRow(
                icon: Icons.event_outlined,
                title: 'checkout.timing_scheduled'.tr(),
                subtitle: slot == null
                    ? 'checkout.timing_scheduled_sub'.tr()
                    : '${Formatters.date(context.locale.languageCode, slot.startAt)} '
                          '· ${Formatters.isolate(slot.label)}',
                selected: timing == DeliveryTiming.scheduled,
                onTap: () => _pick(context, DeliveryTiming.scheduled),
              ),
          ],
        ),
      ),
    );
  }
}
