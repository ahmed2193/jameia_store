import 'package:flutter/material.dart';

import '../../../../../core/design/hero_icons.dart';
import '../../../domain/entities/wallet_entry_entity.dart';

/// Title key and icon of each wallet transaction kind.
abstract final class WalletEntryLabel {
  static String keyOf(WalletEntryKind kind) => switch (kind) {
    WalletEntryKind.refund => 'wallet.tx_refund',
    WalletEntryKind.checkout => 'wallet.tx_checkout',
    WalletEntryKind.cashback => 'wallet.tx_cashback',
    WalletEntryKind.adminAdjustment => 'wallet.tx_admin_adjustment',
    WalletEntryKind.promo => 'wallet.tx_promo',
    WalletEntryKind.other => 'wallet.tx_other',
  };

  static IconData iconOf(WalletEntryKind kind) => switch (kind) {
    WalletEntryKind.refund => HeroIcons.refresh,
    WalletEntryKind.checkout => HeroIcons.bag,
    WalletEntryKind.cashback => HeroIcons.savings,
    WalletEntryKind.adminAdjustment => HeroIcons.filter,
    WalletEntryKind.promo => HeroIcons.gift,
    WalletEntryKind.other => HeroIcons.wallet,
  };
}
