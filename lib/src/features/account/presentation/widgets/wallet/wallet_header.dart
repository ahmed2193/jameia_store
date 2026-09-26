import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../ledger/ledger_section_title.dart';
import 'wallet_balance_card.dart';

/// Top of the wallet screen: the balance card and the history title.
class WalletHeader extends StatelessWidget {
  const WalletHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            AppSpacing.s16,
            AppSpacing.s16,
            AppSpacing.s16,
            0,
          ),
          child: WalletBalanceCard(),
        ),
        LedgerSectionTitle('wallet.history'.tr()),
      ],
    );
  }
}
