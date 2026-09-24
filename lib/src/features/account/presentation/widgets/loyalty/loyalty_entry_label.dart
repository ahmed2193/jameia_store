import 'package:flutter/material.dart';

import '../../../domain/entities/loyalty_entry_entity.dart';

/// Title key and icon of each points transaction kind.
abstract final class LoyaltyEntryLabel {
  static String keyOf(LoyaltyEntryKind kind) => switch (kind) {
    LoyaltyEntryKind.earn => 'loyalty.tx_earn',
    LoyaltyEntryKind.redeem => 'loyalty.tx_redeem',
    LoyaltyEntryKind.expire => 'loyalty.tx_expire',
    LoyaltyEntryKind.welcomeBonus => 'loyalty.tx_welcome_bonus',
    LoyaltyEntryKind.profileBonus => 'loyalty.tx_profile_bonus',
    LoyaltyEntryKind.refundRestore => 'loyalty.tx_refund_restore',
    LoyaltyEntryKind.adminAdjustment => 'loyalty.tx_admin_adjustment',
    LoyaltyEntryKind.other => 'loyalty.tx_other',
  };

  static IconData iconOf(LoyaltyEntryKind kind) => switch (kind) {
    LoyaltyEntryKind.earn => Icons.add_shopping_cart_rounded,
    LoyaltyEntryKind.redeem => Icons.redeem_rounded,
    LoyaltyEntryKind.expire => Icons.hourglass_bottom_rounded,
    LoyaltyEntryKind.welcomeBonus => Icons.celebration_outlined,
    LoyaltyEntryKind.profileBonus => Icons.person_outline_rounded,
    LoyaltyEntryKind.refundRestore => Icons.replay_rounded,
    LoyaltyEntryKind.adminAdjustment => Icons.tune_rounded,
    LoyaltyEntryKind.other => Icons.stars_rounded,
  };
}
