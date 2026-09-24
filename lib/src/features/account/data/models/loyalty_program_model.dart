import '../../../../core/data/models/json_read.dart';

/// `GET /v1/init` → `results.store.loyalty`: `{ enabled, pointsPerKwd,
/// redemptionPerPoint (fils), minRedeemPoints, pointsExpireMonths,
/// welcomeBonusPoints, profileBonusPoints }`. A missing block leaves the
/// programme off.
class LoyaltyProgramModel {
  const LoyaltyProgramModel({
    this.enabled = false,
    this.pointsPerKwd = 0,
    this.redemptionPerPoint = 0,
    this.minRedeemPoints = 0,
    this.pointsExpireMonths = 0,
    this.welcomeBonusPoints = 0,
    this.profileBonusPoints = 0,
  });

  static const String storeKey = 'store';
  static const String loyaltyKey = 'loyalty';
  static const String enabledKey = 'enabled';
  static const String pointsPerKwdKey = 'pointsPerKwd';
  static const String redemptionPerPointKey = 'redemptionPerPoint';
  static const String minRedeemPointsKey = 'minRedeemPoints';
  static const String pointsExpireMonthsKey = 'pointsExpireMonths';
  static const String welcomeBonusPointsKey = 'welcomeBonusPoints';
  static const String profileBonusPointsKey = 'profileBonusPoints';

  /// Reads the `store.loyalty` block of the whole init snapshot.
  factory LoyaltyProgramModel.fromInitJson(Map<String, dynamic> json) {
    final store = JsonRead.object(json[storeKey]);
    final loyalty = JsonRead.object(store?[loyaltyKey]);
    if (loyalty == null) return const LoyaltyProgramModel();
    int read(String key) => JsonRead.integer(loyalty[key]) ?? 0;
    return LoyaltyProgramModel(
      enabled: JsonRead.flag(loyalty[enabledKey]),
      pointsPerKwd: read(pointsPerKwdKey),
      redemptionPerPoint: read(redemptionPerPointKey),
      minRedeemPoints: read(minRedeemPointsKey),
      pointsExpireMonths: read(pointsExpireMonthsKey),
      welcomeBonusPoints: read(welcomeBonusPointsKey),
      profileBonusPoints: read(profileBonusPointsKey),
    );
  }

  final bool enabled;
  final int pointsPerKwd;
  final int redemptionPerPoint;
  final int minRedeemPoints;
  final int pointsExpireMonths;
  final int welcomeBonusPoints;
  final int profileBonusPoints;
}
