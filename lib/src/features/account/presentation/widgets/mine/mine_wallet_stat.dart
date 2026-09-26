import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../core/motion/rolling_number.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../auth/presentation/cubit/auth_session_cubit.dart';
import 'mine_currency_amount.dart';
import 'mine_stat_tile.dart';
import 'mine_tone.dart';

/// The wallet balance stat (the signed-in customer's; a guest shows zero).
/// It paints the cached balance as is and, when the balance changes while
/// the tab is open, rolls only the digits that changed — money never counts
/// up on open. Rebuilds only when the balance changes.
class MineWalletStat extends StatelessWidget {
  const MineWalletStat({super.key});

  @override
  Widget build(BuildContext context) {
    final walletKd = context.select<AuthSessionCubit, double>(
      (cubit) =>
          cubit.state.isSignedIn ? cubit.state.customer?.walletKd ?? 0 : 0,
    );
    return MineStatTile(
      icon: Icons.account_balance_wallet_rounded,
      tone: MineTone.brand,
      label: 'account.wallet'.tr(),
      onTap: () => context.push(Routes.wallet),
      value: MineCurrencyAmount(
        amount: RollingNumber(
          value: walletKd,
          format: (value) => Formatters.amount(value.toDouble()),
          style: MineStatTile.valueStyle,
        ),
      ),
    );
  }
}
