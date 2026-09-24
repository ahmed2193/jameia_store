import '../../domain/entities/ledger.dart';
import '../../domain/entities/loyalty_entry_entity.dart';
import '../../domain/entities/loyalty_program.dart';
import '../models/ledger_page_model.dart';
import '../models/loyalty_entry_model.dart';
import '../models/loyalty_program_model.dart';

extension LoyaltyEntryMapper on LoyaltyEntryModel {
  static const String _earn = 'earn';
  static const String _redeem = 'redeem';
  static const String _expire = 'expire';
  static const String _welcomeBonus = 'welcome_bonus';
  static const String _profileBonus = 'profile_bonus';
  static const String _refundRestore = 'refund_restore';
  static const String _adminAdjustment = 'admin_adjustment';

  LoyaltyEntryEntity toEntity() => LoyaltyEntryEntity(
    id: id,
    kind: switch (type) {
      _earn => LoyaltyEntryKind.earn,
      _redeem => LoyaltyEntryKind.redeem,
      _expire => LoyaltyEntryKind.expire,
      _welcomeBonus => LoyaltyEntryKind.welcomeBonus,
      _profileBonus => LoyaltyEntryKind.profileBonus,
      _refundRestore => LoyaltyEntryKind.refundRestore,
      _adminAdjustment => LoyaltyEntryKind.adminAdjustment,
      _ => LoyaltyEntryKind.other,
    },
    points: pointsDelta,
    createdAt: createdAt,
    expiresAt: expiresAt,
  );
}

extension LoyaltyLedgerMapper on LedgerPageModel<LoyaltyEntryModel> {
  Ledger<LoyaltyEntryEntity> toEntity() => Ledger<LoyaltyEntryEntity>(
    balance: balance,
    entries: [for (final item in items) item.toEntity()],
    page: page,
    hasMore: hasMore,
  );
}

extension LoyaltyProgramMapper on LoyaltyProgramModel {
  LoyaltyProgram toEntity() => LoyaltyProgram(
    enabled: enabled,
    pointsPerKwd: pointsPerKwd,
    redemptionPerPoint: redemptionPerPoint,
    minRedeemPoints: minRedeemPoints,
    pointsExpireMonths: pointsExpireMonths,
    welcomeBonusPoints: welcomeBonusPoints,
    profileBonusPoints: profileBonusPoints,
  );
}
