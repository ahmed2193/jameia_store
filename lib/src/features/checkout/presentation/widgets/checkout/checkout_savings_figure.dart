import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/count_up_text.dart';
import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../domain/entities/checkout_savings_summary.dart';

/// What the coupon and the offers save, under "Coupons & offers": "Add a
/// code", "{code} · saved KD x", "{code} · no saving on this basket",
/// "Offers · saved KD x" or "Saved KD x" (coupon + offers), from the
/// server's totals only ([CheckoutSavingsSummary]).
///
/// The first build is static. A change fades through; a coupon applied
/// after the page opened (on the vouchers page) counts its saving up from
/// zero once — the one count-up of the checkout. A coupon already on the
/// cart at open never counts.
class CheckoutSavingsFigure extends StatefulWidget {
  const CheckoutSavingsFigure({super.key});

  @override
  State<CheckoutSavingsFigure> createState() => _CheckoutSavingsFigureState();
}

class _CheckoutSavingsFigureState extends State<CheckoutSavingsFigure> {
  /// The coupon on the cart when this mounted ('' without one).
  late final String _codeAtOpen;

  @override
  void initState() {
    super.initState();
    _codeAtOpen = context.read<CartCubit>().state.cart.coupon?.code ?? '';
  }

  static String _text(CheckoutSavingsSummary summary, double kd) {
    final code = Formatters.isolate(summary.code);
    final amount = Formatters.price(kd);
    return switch (summary.kind) {
      CheckoutSavingsKind.none => 'checkout.savings_add_code'.tr(),
      CheckoutSavingsKind.code => 'checkout.savings_code_saved'.tr(
        namedArgs: {'code': code, 'amount': amount},
      ),
      CheckoutSavingsKind.codeNoSaving => 'checkout.savings_code_no_saving'.tr(
        namedArgs: {'code': code},
      ),
      CheckoutSavingsKind.offers => 'checkout.savings_offers_saved'.tr(
        namedArgs: {'amount': amount},
      ),
      CheckoutSavingsKind.combined => 'checkout.savings_total'.tr(
        namedArgs: {'amount': amount},
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final summary = context.select<CartCubit, CheckoutSavingsSummary>(
      (cubit) => CheckoutSavingsSummary.of(cubit.state.cart),
    );
    final saves =
        summary.kind != CheckoutSavingsKind.none &&
        summary.kind != CheckoutSavingsKind.codeNoSaving;
    final style = saves
        ? AppTextStyles.label.copyWith(color: AppColors.errorDeep)
        : AppTextStyles.meta;
    final countsUp =
        saves && summary.code.isNotEmpty && summary.code != _codeAtOpen;
    return FadeThroughSwitcher(
      // A new code mounts a fresh figure, so its saving counts from zero.
      stateKey: (summary.kind, summary.code),
      alignment: AlignmentDirectional.centerStart,
      child: countsUp
          ? CountUpText(
              value: summary.kd,
              from: 0,
              format: (kd) => _text(summary, kd),
              style: style,
              maxLines: 1,
            )
          : Text(
              _text(summary, summary.kd),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
    );
  }
}
