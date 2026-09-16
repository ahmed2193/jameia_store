import 'package:easy_localization/easy_localization.dart';

import '../../../../core/data/keeta_repository.dart';
import '../../domain/entities/invite_friends.dart';
import '../../domain/entities/punctual_landing.dart';

/// Offline source for the marketing surfaces (on-time guarantee landing +
/// invite-friends referral).
///
/// The live KeeTa build hits `v1/order/late/compensation/landing` for the
/// punctual page and a referral service for the invite page; the dummy build has
/// no such endpoints, so both payloads are served from the single in-memory
/// [KeetaRepository] backend. The promise/steps/FAQ are static marketing copy and
/// the invite code is derived from the signed-in user.
///
/// `.tr()` is resolved at call time (not cached) so each page open renders in the
/// current locale — matching the old page-scoped-cubit behavior.
abstract class MarketingLocalDataSource {
  /// On-time guarantee landing payload (promise + coupon + steps + FAQ).
  PunctualLanding punctualLanding();

  /// Invite-friends referral snapshot (code + reward tiers + earned summary).
  InviteFriends inviteFriends();
}

class MarketingLocalDataSourceImpl implements MarketingLocalDataSource {
  MarketingLocalDataSourceImpl(this.catalog);

  final KeetaRepository catalog;

  /// Built (not `const`) so `.tr()` resolves to the active locale each fetch. The
  /// landing screen is page-scoped and re-fetches on navigation, so this reflects
  /// the current language.
  @override
  PunctualLanding punctualLanding() => PunctualLanding(
        promiseTitle: 'marketing.punctual_promise_title'.tr(),
        promiseBody: 'marketing.punctual_promise_body'.tr(),
        couponTitle: 'marketing.punctual_coupon_title'.tr(),
        couponBody: 'marketing.punctual_coupon_body'.tr(),
        steps: <PunctualStep>[
          PunctualStep(
            title: 'marketing.punctual_step1_title'.tr(),
            body: 'marketing.punctual_step1_body'.tr(),
          ),
          PunctualStep(
            title: 'marketing.punctual_step2_title'.tr(),
            body: 'marketing.punctual_step2_body'.tr(),
          ),
          PunctualStep(
            title: 'marketing.punctual_step3_title'.tr(),
            body: 'marketing.punctual_step3_body'.tr(),
          ),
        ],
        faqs: <PunctualFaq>[
          PunctualFaq(
            question: 'marketing.punctual_faq1_q'.tr(),
            answer: 'marketing.punctual_faq1_a'.tr(),
          ),
          PunctualFaq(
            question: 'marketing.punctual_faq2_q'.tr(),
            answer: 'marketing.punctual_faq2_a'.tr(),
          ),
          PunctualFaq(
            question: 'marketing.punctual_faq3_q'.tr(),
            answer: 'marketing.punctual_faq3_a'.tr(),
          ),
          PunctualFaq(
            question: 'marketing.punctual_faq4_q'.tr(),
            answer: 'marketing.punctual_faq4_a'.tr(),
          ),
        ],
      );

  @override
  InviteFriends inviteFriends() => InviteFriends(
        referralCode: _referralCode(),
        // Per-referral reward shown in the hero headline + step list (dummy KD).
        rewardPerFriend: 2.000,
        // Aggregate earned summary (dummy): friends joined + total/pending KD.
        friendsJoined: 7,
        totalEarned: 14.000,
        pendingEarned: 4.000,
      );

  /// Dummy referral code derived from the signed-in user (stable, offline).
  String _referralCode() {
    final id = catalog.user.id.toUpperCase().replaceAll('-', '');
    final tail =
        id.length >= 4 ? id.substring(id.length - 4) : id.padLeft(4, '0');
    return 'KEETA$tail';
  }
}
