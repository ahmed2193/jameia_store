import 'package:flutter/material.dart';

import '../../../../../core/design/hero_icons.dart';
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
    LoyaltyEntryKind.earn => HeroIcons.cartAdd,
    LoyaltyEntryKind.redeem => HeroIcons.gift,
    LoyaltyEntryKind.expire => HeroIcons.hourglass,
    LoyaltyEntryKind.welcomeBonus => HeroIcons.party,
    LoyaltyEntryKind.profileBonus => HeroIcons.person,
    LoyaltyEntryKind.refundRestore => HeroIcons.refresh,
    LoyaltyEntryKind.adminAdjustment => HeroIcons.filter,
    LoyaltyEntryKind.other => HeroIcons.points,
  };
}
