import '../../domain/entities/loyalty_program.dart';
import '../models/loyalty_program_model.dart';

/// [LoyaltyProgramModel] (`/v1/init` → `store.loyalty`) → [LoyaltyProgram].
/// Shared by the account screens and the checkout's store rules.
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
