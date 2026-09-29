import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_shadows.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/widgets/segmented_thumb_track.dart';
import '../../domain/entities/pro_membership.dart';
import 'pro_plan_pill.dart';

/// The plan tabs laid out as equal slots of [pillWidth] separated by [gap]
/// on the app's one thumb track ([SegmentedThumbTrack]): one dark thumb
/// slides (calm spring, RTL-aware) under the selected slot, the see-through
/// pills sit on top, and picking another plan fires the selection haptic.
/// [savings] holds each plan's "Save N%" (0 = no chip); [onSelect] is
/// `null` while the tabs are inert.
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

  static const Widget _thumb = DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.primaryText,
      borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
      boxShadow: AppShadows.medium,
    ),
  );

  final List<ProPlan> plans;
  final List<int> savings;

  /// -1 when no plan is selected (no thumb).
  final int selectedIndex;
  final double pillWidth;
  final double gap;
  final ValueChanged<String>? onSelect;

  @override
  Widget build(BuildContext context) {
    final select = onSelect;
    return SizedBox(
      height: ProPlanPill.height,
      child: SegmentedThumbTrack(
        count: plans.length,
        selected: selectedIndex,
        slotWidth: pillWidth,
        gap: gap,
        // The saving chip rises above the pills' top edge.
        clipBehavior: Clip.none,
        thumb: _thumb,
        onSelected: select == null ? null : (i) => select(plans[i].id),
        segmentBuilder: (context, i, tap, _) => ProPlanPill(
          plan: plans[i],
          selected: i == selectedIndex,
          savingPercent: savings[i],
          onTap: tap,
        ),
      ),
    );
  }
}
