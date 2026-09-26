import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import '../cubit/pro_membership_cubit.dart';
import '../cubit/pro_membership_state.dart';
import 'pro_plan_segments.dart';

/// The plan tabs at the top of the paywall: one pill per plan, sharing the
/// row when they fit, scrolling sideways otherwise, with one selection thumb
/// gliding between them. The best-value plan wears the "Save N%" chip (see
/// `ProMembershipState.planSavings`). Slides down into place when the paywall
/// first shows. Inert while a subscribe / cancel is in flight, and for a
/// member (on their own plan, no chip).
class ProPlanTabs extends StatelessWidget {
  const ProPlanTabs({super.key});

  /// More plans than this scroll instead of sharing the row.
  static const int _maxFitted = 3;
  static const double _scrollPillWidth = AppSize.s140;
  static const double _gap = AppSpacing.s12;

  /// The tabs drop in from above by this share of their height.
  static const Offset _dropIn = Offset(0, -0.3);

  /// Room above the pills for the saving chip.
  static const EdgeInsetsDirectional _padding = EdgeInsetsDirectional.fromSTEB(
    AppSpacing.s16,
    AppSpacing.s20,
    AppSpacing.s16,
    AppSpacing.s20,
  );

  @override
  Widget build(BuildContext context) {
    return StaggerEntrance(
      index: 0,
      beginOffset: _dropIn,
      child: BlocBuilder<ProMembershipCubit, ProMembershipState>(
        buildWhen: (previous, current) =>
            previous.program != current.program ||
            previous.selectedPlanId != current.selectedPlanId ||
            previous.isBusy != current.isBusy ||
            previous.isMember != current.isMember,
        builder: (context, state) {
          final cubit = context.read<ProMembershipCubit>();
          final plans = state.program.plans;
          if (plans.isEmpty) return const SizedBox.shrink();
          final savings = state.planSavings;
          final selectedIndex = plans.indexWhere(
            (plan) => plan.id == state.selectedPlanId,
          );
          // A member has nothing to switch to: the tabs stay on their plan.
          final onSelect = state.isBusy || state.isMember
              ? null
              : cubit.selectPlan;
          if (plans.length <= _maxFitted) {
            return Padding(
              padding: _padding,
              child: LayoutBuilder(
                builder: (context, constraints) => ProPlanSegments(
                  plans: plans,
                  savings: savings,
                  selectedIndex: selectedIndex,
                  pillWidth:
                      (constraints.maxWidth - _gap * (plans.length - 1)) /
                      plans.length,
                  gap: _gap,
                  onSelect: onSelect,
                ),
              ),
            );
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: _padding,
            child: ProPlanSegments(
              plans: plans,
              savings: savings,
              selectedIndex: selectedIndex,
              pillWidth: _scrollPillWidth,
              gap: _gap,
              onSelect: onSelect,
            ),
          );
        },
      ),
    );
  }
}
