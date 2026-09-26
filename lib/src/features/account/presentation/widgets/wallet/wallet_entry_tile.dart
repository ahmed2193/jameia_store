import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../../domain/entities/wallet_entry_entity.dart';
import '../ledger/ledger_dates.dart';
import '../ledger/ledger_entry_tile.dart';
import '../ledger/ledger_signed.dart';
import 'wallet_entry_label.dart';

/// One wallet transaction: kind, time, the store's note and the signed
/// amount in dinar.
class WalletEntryTile extends StatelessWidget {
  const WalletEntryTile({super.key, required this.entry});

  final WalletEntryEntity entry;

  @override
  Widget build(BuildContext context) {
    return LedgerEntryTile(
      icon: WalletEntryLabel.iconOf(entry.kind),
      title: WalletEntryLabel.keyOf(entry.kind).tr(),
      time: LedgerDates.time(context.locale.languageCode, entry.createdAt),
      detail: entry.note,
      amount: LedgerSigned.money(
        entry.amountKd,
        rtl: Directionality.of(context) == TextDirection.rtl,
      ),
      isCredit: entry.isCredit,
    );
  }
}
