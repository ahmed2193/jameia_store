import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/formatters.dart';
import '../../../domain/entities/wallet_entry_entity.dart';
import '../../cubit/ledger_cubit.dart';
import '../../cubit/ledger_state.dart';
import '../ledger/ledger_balance_card.dart';
import '../ledger/ledger_section_title.dart';

/// Wallet balance (as the ledger reply sent it) + the history title.
class WalletHeader extends StatelessWidget {
  const WalletHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      LedgerCubit<WalletEntryEntity>,
      LedgerState<WalletEntryEntity>,
      int
    >(
      selector: (state) => state.ledger.balance,
      builder: (context, balanceFils) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LedgerBalanceCard(
            icon: Icons.account_balance_wallet_outlined,
            label: 'wallet.balance'.tr(),
            value: Formatters.price(WalletEntryEntity.kdOf(balanceFils)),
          ),
          LedgerSectionTitle('wallet.history'.tr()),
        ],
      ),
    );
  }
}
