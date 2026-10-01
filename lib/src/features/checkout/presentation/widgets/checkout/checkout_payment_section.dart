import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/domain/entities/order_status.dart';
import '../../../../../core/motion/change_bump.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/option_row.dart';
import '../../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../cubit/checkout_cart_facts_of.dart';
import '../../cubit/checkout_cubit.dart';
import 'checkout_payment_icon.dart';
import 'checkout_section.dart';
import 'checkout_ui_controller.dart';

/// "Payment method": cash on delivery or the wallet — the two methods
/// `POST /v1/orders` takes (`paymentMethod`), one per order, never split.
///
/// Cash on delivery follows the store (`GET /v1/init` →
/// `store.payment.codEnabled`): off, the row stays in place, disabled, and
/// says so. The wallet row shows for a signed-in customer and is disabled
/// while its balance is under the total, with what is missing, instead of
/// letting the customer pick it and meet a refusal at "Place order".
///
/// When the page switches the method on the customer's behalf (the total
/// outgrew the wallet), `CheckoutUiController.bumpPayment` makes the rows
/// bump once so the eye lands here (no haptic: the change is passive).
class CheckoutPaymentSection extends StatelessWidget {
  const CheckoutPaymentSection({super.key});

  /// A whole-section bump stays small.
  static const double _bumpPeak = 1.02;

  @override
  Widget build(BuildContext context) {
    final choice = context
        .select<CheckoutCubit, ({OrderPaymentMethod method, bool codEnabled})>(
          (cubit) => (
            method: cubit.state.draft.paymentMethod,
            codEnabled: cubit.state.rules.codEnabled,
          ),
        );
    final wallet = context.select<AuthSessionCubit, ({int fils, double kd})?>(
      (session) => switch (session.state.customer) {
        null => null,
        final customer => (fils: customer.walletFils, kd: customer.walletKd),
      },
    );
    // The domain's own rule (`CheckoutCartFacts.walletCovers`), the one
    // placing the order checks.
    final covers = context.select<CartCubit, bool>(
      (cubit) =>
          wallet != null &&
          cubit.state.checkoutFacts(walletFils: wallet.fils).walletCovers,
    );
    final ui = context.read<CheckoutUiController>();
    return CheckoutSection(
      title: 'checkout.payment_method_title'.tr(),
      padding: EdgeInsetsDirectional.zero,
      child: ValueListenableBuilder<int>(
        valueListenable: ui.paymentBumps,
        builder: (_, bumps, rows) =>
            ChangeBump(value: bumps, peak: _bumpPeak, child: rows!),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            OptionRow(
              leading: const CheckoutPaymentIcon(icon: HeroIcons.cash),
              title: 'checkout.pay_cod'.tr(),
              subtitle: choice.codEnabled ? null : 'checkout.pay_cod_off'.tr(),
              enabled: choice.codEnabled,
              selected: choice.method == OrderPaymentMethod.cod,
              onTap: () => context.read<CheckoutCubit>().setPaymentMethod(
                OrderPaymentMethod.cod,
              ),
            ),
            if (wallet != null) ...[
              const Divider(
                height: AppSize.s1,
                thickness: AppSize.s1,
                color: AppColors.divider,
                indent: AppSpacing.s12,
              ),
              OptionRow(
                leading: const CheckoutPaymentIcon(
                  plate: HeroAssets.checkoutWallet,
                ),
                title: 'checkout.pay_wallet'.tr(),
                subtitle:
                    (covers
                            ? 'checkout.wallet_balance'
                            : 'checkout.wallet_short')
                        .tr(namedArgs: {'amount': Formatters.price(wallet.kd)}),
                enabled: covers,
                selected: choice.method == OrderPaymentMethod.wallet,
                onTap: () => context.read<CheckoutCubit>().setPaymentMethod(
                  OrderPaymentMethod.wallet,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
