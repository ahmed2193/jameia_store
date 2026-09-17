import 'package:equatable/equatable.dart';

import 'user_profile_entity.dart';

/// Snapshot for the Jameia "Mine" tab (`mach_pro_sailor_c_mine`) — the signed-in
/// profile plus the header quick-stat counts and the customer-service unread
/// badge count. Holds the framework-free [UserProfileEntity].
class AccountOverview extends Equatable {
  const AccountOverview({
    required this.user,
    required this.couponCount,
    required this.favouriteCount,
    required this.customerServiceUnread,
  });

  /// Signed-in profile shown in the header + delivery-code cell.
  final UserProfileEntity user;

  /// Unused coupons → the "Coupons" quick-stat.
  final int couponCount;

  /// Favourite shops → the "Favourites" quick-stat.
  final int favouriteCount;

  /// Unread customer-service messages → the menu-cell badge (0 hides it).
  final int customerServiceUnread;

  @override
  List<Object?> get props => [
    user,
    couponCount,
    favouriteCount,
    customerServiceUnread,
  ];
}
