import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/invite_friends.dart';
import '../entities/punctual_landing.dart';

/// Read boundary for the marketing surfaces. Offline, both methods resolve from
/// the scripted marketing source; they still return `Either<Failure, T>` so the
/// presentation layer handles failure uniformly.
abstract class MarketingRepository {
  /// On-time guarantee landing payload (promise + coupon + steps + FAQ).
  Future<Either<Failure, PunctualLanding>> getPunctualLanding();

  /// Invite-friends referral snapshot (code + reward tiers + earned summary).
  Future<Either<Failure, InviteFriends>> getInviteFriends();
}
