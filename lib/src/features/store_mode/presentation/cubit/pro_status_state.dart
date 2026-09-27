import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/pro_membership_entity.dart';
import '../../domain/entities/pro_membership.dart';

/// App-global Pro status: where the customer stands with Pro and what the
/// store sells. Other features select plain values from it
/// ([membership], [canOffer], [offersFreeDelivery]) and never need the
/// programme's own types.
class ProStatusState extends Equatable {
  const ProStatusState({
    this.membership = ProMembershipEntity.guest,
    this.isSettled = false,
    this.isConfirmed = false,
    this.program = ProProgram.empty,
    this.isProgramLoaded = false,
  });

  /// A guest until the session says otherwise.
  final ProMembershipEntity membership;

  /// The standing is known: the session resolved (signed in with a customer
  /// record, or signed out). Until then no surface guesses — no member badge,
  /// no upsell.
  final bool isSettled;

  /// The subscription route answered for this session, so a renewing member,
  /// one who cancelled and a lapsed one are told apart; `false` while only
  /// the customer record speaks.
  final bool isConfirmed;

  /// The programme the store sells (perks + plans); [ProProgram.empty] until
  /// [isProgramLoaded].
  final ProProgram program;
  final bool isProgramLoaded;

  /// Pro may be offered to this customer: the standing is known, the store
  /// sells Pro, and the customer does not already have the perks.
  bool get canOffer =>
      isSettled && membership.canJoin && !program.isUnavailable;

  /// Pro includes free delivery (what the cart nudge sells).
  bool get offersFreeDelivery => canOffer && program.perks.freeDelivery;

  /// The customer's delivery is free because they are a member (the cart's
  /// "Free · pro").
  bool get memberFreeDelivery =>
      membership.hasBenefits && program.perks.freeDelivery;

  ProStatusState copyWith({
    ProMembershipEntity? membership,
    bool? isSettled,
    bool? isConfirmed,
    ProProgram? program,
    bool? isProgramLoaded,
  }) => ProStatusState(
    membership: membership ?? this.membership,
    isSettled: isSettled ?? this.isSettled,
    isConfirmed: isConfirmed ?? this.isConfirmed,
    program: program ?? this.program,
    isProgramLoaded: isProgramLoaded ?? this.isProgramLoaded,
  );

  @override
  List<Object?> get props => [
    membership,
    isSettled,
    isConfirmed,
    program,
    isProgramLoaded,
  ];
}
