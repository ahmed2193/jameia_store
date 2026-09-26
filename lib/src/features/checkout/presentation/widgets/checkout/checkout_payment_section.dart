import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/domain/entities/order_status.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/jameia_list_card.dart';
import '../../../../../core/widgets/option_row.dart';
import '../../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../cubit/checkout_cubit.dart';
import 'checkout_section.dart';

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
    final covers = wallet != null && wallet.$1 >= totalFils;
    return CheckoutSection(
      title: 'checkout.payment_title'.tr(),
      child: JameiaListCard(
        children: [
          OptionRow(
            icon: Icons.payments_outlined,
            title: 'checkout.pay_cod'.tr(),
            selected: method == OrderPaymentMethod.cod,
            onTap: () => context.read<CheckoutCubit>().setPaymentMethod(
              OrderPaymentMethod.cod,
            ),
          ),
          if (wallet != null)
            OptionRow(
              icon: Icons.account_balance_wallet_outlined,
              title: 'checkout.pay_wallet'.tr(),
              subtitle:
                  (covers ? 'checkout.wallet_balance' : 'checkout.wallet_short')
                      .tr(namedArgs: {'amount': Formatters.price(wallet.$2)}),
              enabled: covers,
              selected: method == OrderPaymentMethod.wallet,
              onTap: () => context.read<CheckoutCubit>().setPaymentMethod(
                OrderPaymentMethod.wallet,
              ),
            ),
        ],
      ),
    );
  }
}
