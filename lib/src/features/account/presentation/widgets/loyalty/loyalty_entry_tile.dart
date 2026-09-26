import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../../domain/entities/loyalty_entry_entity.dart';
import '../ledger/ledger_dates.dart';
import '../ledger/ledger_entry_tile.dart';
import '../ledger/ledger_signed.dart';
import 'loyalty_entry_label.dart';

/// One points transaction: kind, time, when earned points lapse and the
/// signed points.
class LoyaltyEntryTile extends StatelessWidget {
  const LoyaltyEntryTile({super.key, required this.entry});

  final LoyaltyEntryEntity entry;

  @override
  Widget build(BuildContext context) {
    final languageCode = context.locale.languageCode;
    final expiresAt = entry.expiresAt;
    return LedgerEntryTile(
      icon: LoyaltyEntryLabel.iconOf(entry.kind),
      title: LoyaltyEntryLabel.keyOf(entry.kind).tr(),
      time: LedgerDates.time(languageCode, entry.createdAt),
      detail: expiresAt == null || !entry.isCredit
          ? ''
          : 'loyalty.expires_on'.tr(
              namedArgs: {
                'date': DateFormat.yMMMd(languageCode)
                    .format(expiresAt.toLocal()),
              },
            ),
      amount: 'loyalty.points_value'.tr(
        namedArgs: {
          'points': LedgerSigned.number(
            entry.points,
            rtl: Directionality.of(context) == TextDirection.rtl,
          ),
        },
      ),
      isCredit: entry.isCredit,
    );
  }
}
