import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/utils/formatters.dart';
import '../../../domain/entities/wallet_entry_entity.dart';
import '../ledger/ledger_entry_tile.dart';
import 'wallet_entry_label.dart';

/// One wallet transaction: kind, date, the store's note and the signed
/// amount in dinar.
class WalletEntryTile extends StatelessWidget {
  const WalletEntryTile({super.key, required this.entry});

  final WalletEntryEntity entry;

  @override
  Widget build(BuildContext context) {
    final sign = entry.amountFils < 0 ? '−' : '+';
    return LedgerEntryTile(
      icon: WalletEntryLabel.iconOf(entry.kind),
      title: WalletEntryLabel.keyOf(entry.kind).tr(),
      date: Formatters.dateTime(context.locale.languageCode, entry.createdAt),
      detail: entry.note,
      amount: '$sign${Formatters.price(entry.amountKd.abs())}',
      isCredit: entry.isCredit,
    );
  }
}
