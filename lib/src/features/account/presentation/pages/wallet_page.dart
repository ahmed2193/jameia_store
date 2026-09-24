import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../../domain/entities/wallet_entry_entity.dart';
import '../cubit/ledger_cubit.dart';
import '../widgets/ledger/ledger_app_bar.dart';
import '../widgets/ledger/ledger_body.dart';
import '../widgets/ledger/ledger_failure_listener.dart';
import '../widgets/wallet/wallet_entry_tile.dart';
import '../widgets/wallet/wallet_header.dart';

/// Mine → Wallet: the balance and its transactions (`GET
/// /v1/account/wallet`, signed-in only, paginated).
class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LedgerCubit<WalletEntryEntity>>()..load(),
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: LedgerAppBar(title: 'wallet.title'.tr()),
        body: LedgerFailureListener<WalletEntryEntity>(
          loadMoreFailedMessage: 'wallet.load_more_failed'.tr(),
          child: LedgerBody<WalletEntryEntity>(
            header: const WalletHeader(),
            entryBuilder: (entry) => WalletEntryTile(entry: entry),
            emptyIcon: Icons.account_balance_wallet_outlined,
            emptyMessage: 'wallet.empty'.tr(),
            signInMessage: 'wallet.sign_in_prompt'.tr(),
          ),
        ),
      ),
    );
  }
}
