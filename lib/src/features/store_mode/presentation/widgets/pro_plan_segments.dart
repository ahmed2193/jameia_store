import 'package:flutter/material.dart';

import '../../domain/entities/pro_membership.dart';
import 'pro_plan_pill.dart';
import 'pro_plan_thumb.dart';

/// The plan tabs laid out as equal slots of [pillWidth] separated by [gap]:
/// one dark thumb glides under the selected slot and the see-through pills
/// sit on top. [savings] holds each plan's "Save N%" (0 = no chip);
/// [onSelect] is `null` while the tabs are inert.
class ProPlanSegments extends StatelessWidget {
  const ProPlanSegments({
    super.key,
    required this.plans,
    required this.savings,
    required this.selectedIndex,
    required this.pillWidth,
    required this.gap,
    required this.onSelect,
  });

  final List<ProPlan> plans;
  final List<int> savings;

  /// -1 when no plan is selected (no thumb).
  final int selectedIndex;
  final double pillWidth;
  final double gap;
  final ValueChanged<String>? onSelect;

  double _startOf(int index) => index * (pillWidth + gap);

  @override
  Widget build(BuildContext context) {
    final select = onSelect;
    final count = plans.length;
    return SizedBox(
      width: count * pillWidth + (count - 1) * gap,
      height: ProPlanPill.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (selectedIndex >= 0)
            ProPlanThumb(start: _startOf(selectedIndex), width: pillWidth),
          for (var i = 0; i < count; i++)
            PositionedDirectional(
              key: ValueKey<String>(plans[i].id),
              start: _startOf(i),
              width: pillWidth,
              top: 0,
              bottom: 0,
              child: ProPlanPill(
                plan: plans[i],
                selected: i == selectedIndex,
                savingPercent: savings[i],
                onTap: select == null ? null : () => select(plans[i].id),
              ),
            ),
        ],
      ),
    );
  }
}
