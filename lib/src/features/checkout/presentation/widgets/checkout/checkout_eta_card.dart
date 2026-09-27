import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import '../../../../../core/motion/second_clock_scope.dart';
import '../../../../../core/widgets/hero_list_row.dart';
import '../../../../../core/widgets/hero_surface_card.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../domain/entities/checkout_eta.dart';
import '../../cubit/checkout_cart_facts_of.dart';
import '../../cubit/checkout_cubit.dart';
import 'checkout_eta_card_text.dart';
import 'checkout_info_sheet.dart';
import 'checkout_ui_controller.dart';

/// The green card under the "Expected" row, where Hero shows its On-Time
/// Promise — here only what the order really has: when an ASAP / express
/// order should arrive, or the window the customer booked. Starts at the
/// row's text column. Hidden (it folds away) for pickup, before a
/// destination is priced, and while the branch is closed or has no
/// capacity. A tap explains how the time is estimated. The clock time is
/// recomputed once a minute by a card-local minute clock, which rests while
/// the page is covered.
class CheckoutEtaCard extends StatelessWidget {
  const CheckoutEtaCard({super.key});

  static const Duration _minute = Duration(minutes: 1);

  @override
  Widget build(BuildContext context) {
    final facts = context.select<CartCubit, CheckoutEtaCartFacts>(
      (cubit) => cubit.state.etaFacts,
    );
    final eta = context.select<CheckoutCubit, CheckoutEta>(
      (cubit) => cubit.state.etaWith(facts),
    );
    final ui = context.read<CheckoutUiController>();
    return CollapseReveal(
      visible: eta.showsCard,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          start: HeroListRow.denseTextStart,
          end: AppSpacing.s12,
        ),
        child: HeroSurfaceCard(
          tone: HeroSurfaceTone.brand,
          radius: AppRadius.card,
          padding: const EdgeInsets.all(AppSpacing.s8),
          onTap: () => CheckoutInfoSheet.show(
            context,
            title: 'checkout.eta_info_title'.tr(),
            body: 'checkout.eta_info_body'.tr(),
          ),
          child: SecondClockScope(
            clock: ui.clock,
            period: _minute,
            child: CheckoutEtaCardText(eta: eta),
          ),
        ),
      ),
    );
  }
}
