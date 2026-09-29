import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/motion/second_clock_scope.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/hero_svg_glyph.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../domain/entities/checkout_eta.dart';
import '../../cubit/checkout_cubit.dart';
import 'checkout_slot_sheet.dart';

/// The words of the ETA card: "Arrives around 5:55 PM" (ASAP), "Express ·
/// arrives around …" with its minutes and fee, or "Arrives Tomorrow, 10:00
/// – 12:00" (a booked window), each with an honest note under it. The clock
/// time is [CheckoutEta.arrivesAround] of the enclosing minute clock
/// (`SecondClockScope`), so it moves on as time passes and never promises
/// earlier than the server's estimate. A new kind fades through.
class CheckoutEtaCardText extends StatelessWidget {
  const CheckoutEtaCardText({super.key, required this.eta});

  final CheckoutEta eta;

  @override
  Widget build(BuildContext context) {
    final languageCode = context.locale.languageCode;
    final expressFeeKd = context.select<CartCubit, double>(
      (cubit) => cubit.state.cart.expressFeeKd,
    );
    final slot = eta.slot;
    final slotDay = context.select<CheckoutCubit, String?>(
      (cubit) => slot == null
          ? null
          : CheckoutSlotSheet.slotDayText(
              languageCode,
              cubit.state.slotDays,
              slot,
            ),
    );
    final clock = SecondClockScope.maybeOf(context)!;
    return ListenableBuilder(
      listenable: clock,
      builder: (context, _) {
        final at = eta.arrivesAround(clock.now);
        final time = at == null ? '' : Formatters.clock(languageCode, at);
        final minutes = eta.minutes ?? 0;
        final (title, note) = switch (eta.kind) {
          CheckoutEtaKind.express => (
            'checkout.eta_express_arrives'.tr(namedArgs: {'time': time}),
            'checkout.eta_express_note'.plural(
              minutes,
              namedArgs: {'amount': Formatters.price(expressFeeKd)},
            ),
          ),
          CheckoutEtaKind.scheduled => (
            'checkout.eta_slot_arrives'.tr(
              namedArgs: {
                'day': slotDay ?? '',
                'window': Formatters.isolate(slot?.label ?? ''),
              },
            ),
            'checkout.eta_slot_note'.tr(),
          ),
          _ => (
            'checkout.eta_arrives'.tr(namedArgs: {'time': time}),
            'checkout.eta_note'.tr(),
          ),
        };
        return FadeThroughSwitcher(
          stateKey: eta.kind,
          alignment: AlignmentDirectional.topStart,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HeroSvgGlyph.mono(
                HeroAssets.sharedClock,
                size: AppSize.s18,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: AppTextStyles.label.copyWith(
                              fontWeight: AppTextStyles.bold,
                              color: AppColors.brandDeep,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s4),
                        const Icon(
                          Icons.info_outline_rounded,
                          size: AppSize.s14,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    Text(note, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
