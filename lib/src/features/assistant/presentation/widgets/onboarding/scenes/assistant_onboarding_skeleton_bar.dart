import 'package:flutter/material.dart';

import '../../../../../../config/theme/app_colors.dart';
import '../../../../../../config/theme/app_spacing.dart';

/// A grey placeholder line in the ready demo's little phone, [widthFactor]
/// of the room it gets.
class AssistantOnboardingSkeletonBar extends StatelessWidget {
  const AssistantOnboardingSkeletonBar({
    super.key,
    required this.widthFactor,
    required this.height,
    this.color = AppColors.divider,
  });

  final double widthFactor;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: AlignmentDirectional.centerStart,
      child: SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.all(Radius.circular(AppRadius.r6)),
          ),
        ),
      ),
    );
  }
}
