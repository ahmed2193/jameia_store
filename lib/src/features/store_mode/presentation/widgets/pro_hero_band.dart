import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/motion/motion_widgets.dart';
import '../../domain/entities/pro_membership.dart';
import '../cubit/pro_membership_cubit.dart';
import '../cubit/pro_membership_state.dart';
import 'pro_hero_panel.dart';

/// The hero of the selected plan. One panel for every plan: it animates its
/// own parts into the new plan (see [ProHeroPanel]) instead of swapping.
///
/// A plan switch moves in order (backlog B2-03): the tabs' thumb answers
/// the tap, the price and the button follow a beat later, and the hero —
/// the big, decorative part — changes last ([MotionBeat.third]).
class ProHeroBand extends StatelessWidget {
  const ProHeroBand({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ProMembershipCubit, ProMembershipState, ProPlan?>(
      selector: (state) => state.selectedPlan,
      builder: (context, plan) => DeferredValue<ProPlan?>(
        value: plan,
        delay: MotionBeat.third,
        // Only a switch between plans waits; the first plan shows at once.
        deferWhen: (shown, next) => shown != null && next != null,
        builder: (context, shown) =>
            shown == null ? const SizedBox.shrink() : ProHeroPanel(plan: shown),
      ),
    );
  }
}
