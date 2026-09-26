import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/pro_membership.dart';
import '../cubit/pro_membership_cubit.dart';
import '../cubit/pro_membership_state.dart';
import 'pro_hero_panel.dart';

/// The hero of the selected plan. One panel for every plan: it animates its
/// own parts into the new plan (see [ProHeroPanel]) instead of swapping.
class ProHeroBand extends StatelessWidget {
  const ProHeroBand({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ProMembershipCubit, ProMembershipState, ProPlan?>(
      selector: (state) => state.selectedPlan,
      builder: (context, plan) {
        if (plan == null) return const SizedBox.shrink();
        return ProHeroPanel(plan: plan);
      },
    );
  }
}
