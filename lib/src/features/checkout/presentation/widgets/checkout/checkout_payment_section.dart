import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/domain/entities/order_status.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/option_row.dart';
import '../../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../cubit/checkout_cubit.dart';
import 'checkout_section_title.dart';

/// Cash on delivery or the wallet (`POST /v1/orders` → `paymentMethod`).
///
/// `paymentMethod` takes one method for the whole order — the contract has
/// no split payment — so a balance under the total cannot pay for it. That
/// row is offered disabled, with what is missing, instead of letting the
/// customer pick it and meet a rejection at "Place order".
class CheckoutPaymentSection extends StatelessWidget {
  const CheckoutPaymentSection({super.key});

  @override
  Widget build(BuildContext context) {
    final method = context.select<CheckoutCubit, OrderPaymentMethod>(
      (cubit) => cubit.state.draft.paymentMethod,
    );
    final wallet = context.select<AuthSessionCubit, (int, double)?>(
      (session) => switch (session.state.customer) {
        null => null,
        final customer => (customer.walletFils, customer.walletKd),
      },
    );
    final totalFils = context.select<CartCubit, int>(
      (cubit) => cubit.state.cart.totals.totalFils,
    );
    final cubit = context.read<CheckoutCubit>();
    final covers = wallet != null && wallet.$1 >= totalFils;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CheckoutSectionTitle('checkout.payment_title'.tr()),
        OptionRow(
          title: 'checkout.pay_cod'.tr(),
          selected: method == OrderPaymentMethod.cod,
          onTap: () => cubit.setPaymentMethod(OrderPaymentMethod.cod),
        ),
        if (wallet != null)
          OptionRow(
            title: 'checkout.pay_wallet'.tr(),
            subtitle:
                (covers ? 'checkout.wallet_balance' : 'checkout.wallet_short')
                    .tr(namedArgs: {'amount': Formatters.price(wallet.$2)}),
            enabled: covers,
            selected: method == OrderPaymentMethod.wallet,
            onTap: () => cubit.setPaymentMethod(OrderPaymentMethod.wallet),
          ),
      ],
    );
  }
}
