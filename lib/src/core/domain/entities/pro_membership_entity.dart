import 'package:equatable/equatable.dart';

import 'auth_customer_entity.dart';

/// Where the customer stands with Jm3eia Pro. Every Pro surface keys on it:
/// the home header and banner, the Mine row, the cart nudge and the Pro page.
enum ProStanding {
  /// Nobody is signed in: Pro is on sale, and joining starts with sign-in.
  guest,

  /// Signed in and not a member: never was, or the app does not know yet.
  prospect,

  /// A member whose membership renews at [ProMembershipEntity.periodEnd].
  active,

  /// A member who cancelled: the perks stay on until
  /// [ProMembershipEntity.periodEnd], then the membership stops.
  ending,

  /// Was a member and the membership ran out: "rejoin".
  lapsed,
}

/// The customer's Jm3eia Pro membership as the app-global Pro status holds
/// it: the subscription route's answer (`GET /v1/account/subscription`), or
/// the customer record (`customer.pro`) until that answer lands.
class ProMembershipEntity extends Equatable {
  const ProMembershipEntity({
    this.standing = ProStanding.guest,
    this.periodEnd,
    this.planName = '',
  });

  /// What the signed-in customer's record says (`customer.pro`) before the
  /// subscription route answers. The record cannot tell a renewing member
  /// from one who cancelled, so a member counts as renewing until then.
  factory ProMembershipEntity.ofCustomer(AuthCustomerEntity customer) =>
      customer.isPro
      ? ProMembershipEntity(
          standing: ProStanding.active,
          periodEnd: customer.proExpiresAt,
        )
      : prospect;

  /// Nobody is signed in.
  static const ProMembershipEntity guest = ProMembershipEntity();

  /// Signed in, not a member.
  static const ProMembershipEntity prospect = ProMembershipEntity(
    standing: ProStanding.prospect,
  );

  final ProStanding standing;

  /// When the paid period ends: the renewal date ([ProStanding.active]), the
  /// last day of the perks ([ProStanding.ending]) or when they stopped
  /// ([ProStanding.lapsed]); `null` when unknown.
  final DateTime? periodEnd;

  /// The plan's name, resolved for the request language; `''` when unknown.
  final String planName;

  /// The Pro perks are on right now: free delivery, member prices, the
  /// points boost.
  bool get hasBenefits =>
      standing == ProStanding.active || standing == ProStanding.ending;

  bool get isGuest => standing == ProStanding.guest;

  /// Pro is still worth offering: a guest, a prospect or a lapsed member.
  bool get canJoin => !hasBenefits;

  @override
  List<Object?> get props => [standing, periodEnd, planName];
}
