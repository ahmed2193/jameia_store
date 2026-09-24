import 'package:flutter/material.dart';

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
    WalletEntryKind.refund => Icons.replay_rounded,
    WalletEntryKind.checkout => Icons.shopping_bag_outlined,
    WalletEntryKind.cashback => Icons.savings_outlined,
    WalletEntryKind.adminAdjustment => Icons.tune_rounded,
    WalletEntryKind.promo => Icons.card_giftcard_rounded,
    WalletEntryKind.other => Icons.account_balance_wallet_outlined,
  };
}
