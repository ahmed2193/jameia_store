import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/auth_customer_entity.dart';

/// The store's loyalty programme (`GET /v1/init` → `store.loyalty`): how
/// points are earned and spent, and the one-time bonuses.
class LoyaltyProgram extends Equatable {
  const LoyaltyProgram({
    this.enabled = false,
    this.pointsPerKwd = 0,
    this.redemptionPerPoint = 0,
    this.minRedeemPoints = 0,
    this.pointsExpireMonths = 0,
    this.welcomeBonusPoints = 0,
    this.profileBonusPoints = 0,
  });

  /// Nothing known about the programme (not loaded, or it failed to load).
  static const LoyaltyProgram none = LoyaltyProgram();

  static const int filsPerDinar = 1000;

  final bool enabled;

  /// Points earned per 1 KWD spent.
  final int pointsPerKwd;

  /// Discount one point is worth, in fils.
  final int redemptionPerPoint;
  final int minRedeemPoints;

  /// Earned points lapse after this many months; 0 = never.
  final int pointsExpireMonths;
  final int welcomeBonusPoints;

  /// Awarded once when date of birth, gender and household size are filled.
  final int profileBonusPoints;

  /// The discount one point is worth, in dinar (1 fils → 0.001).
  double get pointValueKd => redemptionPerPoint / filsPerDinar;

  /// The discount [points] are worth, in dinar.
  double valueKdOf(int points) => points * redemptionPerPoint / filsPerDinar;

  bool get pointsExpire => pointsExpireMonths > 0;

  /// The profile bonus still on offer to [customer]: the programme runs it
  /// and the customer's details are not complete yet; 0 otherwise.
  int profileBonusFor(AuthCustomerEntity customer) =>
      enabled && profileBonusPoints > 0 && !customer.hasCompleteDetails
      ? profileBonusPoints
      : 0;

  /// Points the save that turned [before] into [after] earned through the
  /// profile bonus: the details became complete and the balance grew.
  static int profileBonusEarned({
    required AuthCustomerEntity before,
    required AuthCustomerEntity after,
  }) {
    if (before.hasCompleteDetails || !after.hasCompleteDetails) return 0;
    final gained = after.loyaltyPoints - before.loyaltyPoints;
    return gained > 0 ? gained : 0;
  }

  @override
  List<Object?> get props => [
    enabled,
    pointsPerKwd,
    redemptionPerPoint,
    minRedeemPoints,
    pointsExpireMonths,
    welcomeBonusPoints,
    profileBonusPoints,
  ];
}
