import 'package:equatable/equatable.dart';

import 'user_profile_entity.dart';

/// Snapshot for the Hero "Mine" tab (`mach_pro_sailor_c_mine`) — the signed-in
/// profile plus the coupons quick-stat count. Holds the framework-free [UserProfileEntity].
class AccountOverview extends Equatable {
  const AccountOverview({required this.user, required this.couponCount});

  /// Signed-in profile shown in the header + delivery-code cell.
  final UserProfileEntity user;

  /// Unused coupons → the "Coupons" quick-stat.
  final int couponCount;

  @override
  List<Object?> get props => [user, couponCount];
}
