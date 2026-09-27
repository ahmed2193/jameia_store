import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/pro_membership_entity.dart';
import '../../../../core/motion/fade_through_switcher.dart';
import '../cubit/pro_membership_cubit.dart';
import 'pro_hero_band.dart';
import 'pro_member_hero.dart';
import 'pro_plan_tabs.dart';

/// Top of the Pro page. A member has nothing to pick: the member hero. Every
/// one else — a guest, a prospect, a lapsed member — the plan tabs over the
/// selected plan's hero. A subscribe fades through from the paywall's top to
/// the member hero (behind the welcome sheet), a cancel re-words it.
class ProTopSection extends StatelessWidget {
  const ProTopSection({super.key});

  /// The paywall's top is one state for the switcher: switching plans
  /// animates inside it (the tabs' thumb, the hero's tween), not here.
  static const Object _offerKey = 'offer';

  @override
  Widget build(BuildContext context) {
    final membership = context.select<ProMembershipCubit, ProMembershipEntity?>(
      (cubit) => cubit.state.isMember ? cubit.state.membership : null,
    );
    return FadeThroughSwitcher(
      stateKey: membership?.standing ?? _offerKey,
      alignment: Alignment.topCenter,
      child: membership == null
          ? const Column(children: [ProPlanTabs(), ProHeroBand()])
          : ProMemberHero(membership: membership),
    );
  }
}
