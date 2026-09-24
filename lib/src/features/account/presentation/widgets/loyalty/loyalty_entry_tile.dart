import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/utils/formatters.dart';
import '../../../domain/entities/loyalty_entry_entity.dart';
import '../ledger/ledger_entry_tile.dart';
import 'loyalty_entry_label.dart';

/// One points transaction: kind, date, when earned points lapse and the
/// signed points.
class LoyaltyEntryTile extends StatelessWidget {
  const LoyaltyEntryTile({super.key, required this.entry});

  final LoyaltyEntryEntity entry;

  @override
  Widget build(BuildContext context) {
    final languageCode = context.locale.languageCode;
    final sign = entry.points < 0 ? '−' : '+';
    final expiresAt = entry.expiresAt;
    return LedgerEntryTile(
      icon: LoyaltyEntryLabel.iconOf(entry.kind),
      title: LoyaltyEntryLabel.keyOf(entry.kind).tr(),
      date: Formatters.dateTime(languageCode, entry.createdAt),
      detail: expiresAt == null || !entry.isCredit
          ? ''
          : 'loyalty.expires_on'.tr(
              namedArgs: {
                'date': DateFormat.yMMMd(languageCode)
                    .format(expiresAt.toLocal()),
              },
            ),
      amount: 'loyalty.points_value'.tr(
        namedArgs: {'points': '$sign${entry.points.abs()}'},
      ),
      isCredit: entry.isCredit,
    );
  }
}
