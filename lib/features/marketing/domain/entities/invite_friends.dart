import 'package:equatable/equatable.dart';

/// Referral / invite-friends snapshot for `mkt_invite_main`.
///
/// The live KeeTa page derives the code from the signed-in user and pulls the
/// reward tiers + earned summary from the referral service; the offline clone
/// builds the same shape from the in-memory backend (stable per user, dummy KD
/// values). All values are resolved once through the marketing datasource so the
/// screen renders from state.
class InviteFriends extends Equatable {
  const InviteFriends({
    required this.referralCode,
    required this.rewardPerFriend,
    required this.friendsJoined,
    required this.totalEarned,
    required this.pendingEarned,
  });

  /// Dummy referral code derived from the signed-in user (stable, offline).
  final String referralCode;

  /// Per-referral reward shown in the hero headline + step list (dummy KD).
  final double rewardPerFriend;

  /// Aggregate earned summary (dummy): friends joined + total/pending KD earned.
  final int friendsJoined;
  final double totalEarned;
  final double pendingEarned;

  @override
  List<Object?> get props =>
      [referralCode, rewardPerFriend, friendsJoined, totalEarned, pendingEarned];
}
