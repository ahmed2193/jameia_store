import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/pro_membership_entity.dart';
import '../../../../core/motion/fade_through_switcher.dart';
import '../../../store_mode/presentation/cubit/pro_status_cubit.dart';
import '../../domain/entities/home_bootstrap.dart';
import 'home_layout.dart';
import 'home_pro_member_banner.dart';
import 'home_pro_offer_banner.dart';

/// The Pro slot at the end of the home feed, keyed on where the customer
/// stands with Pro (the app-global Pro status): the offer for a guest and a
/// non-member ("Join Pro"), a win-back for a lapsed member ("Rejoin"), the
/// member card for a member (renewal date, or when the perks end once
/// cancelled) — never an upsell to someone who has the perks. Empty while
/// the standing is not known, so it never flips from "Join" to "Member".
/// A change (a subscribe, a cancel) fades through to the new card.
class HomeProBanner extends StatelessWidget {
  const HomeProBanner({super.key, required this.pro, required this.onTap});

  /// The programme's perks from the launch snapshot (`init.store.pro`).
  final HomeProInfo pro;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final membership = context.select<ProStatusCubit, ProMembershipEntity?>(
      (status) => status.state.isSettled ? status.state.membership : null,
    );
    if (membership == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        HomeLayout.gutter,
        0,
        HomeLayout.gutter,
        HomeLayout.blockGap,
      ),
      child: FadeThroughSwitcher(
        stateKey: membership.standing,
        child: membership.hasBenefits
            ? HomeProMemberBanner(
                pro: pro,
                membership: membership,
                onTap: onTap,
              )
            : HomeProOfferBanner(
                pro: pro,
                lapsed: membership.standing == ProStanding.lapsed,
                onTap: onTap,
              ),
      ),
    );
  }
}
