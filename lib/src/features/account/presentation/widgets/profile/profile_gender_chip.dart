import 'package:flutter/material.dart';

import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/motion_widgets.dart';
import 'profile_gender_chip_surface.dart';

/// One option of the gender selector. Selecting it fades the fill to the
/// brand colour (colour: [AppMotion.fast], never overshooting) while the
/// corners spring from soft square to pill ([AppSprings.snappy]); reduced
/// motion switches both at once. A selection haptic fires only when the
/// choice actually changes; screen readers hear it as one option of an
/// exclusive group.
class ProfileGenderChip extends StatelessWidget {
  const ProfileGenderChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final target = selected ? 1.0 : 0.0;
    final spring = AppSprings.snappy;
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: selected,
        inMutuallyExclusiveGroup: true,
        child: PressScale(
          onTap: () {
            if (selected) return;
            Haptics.pick();
            onSelected();
          },
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: target),
            duration: MotionGuard.duration(context, AppMotion.fast),
            curve: AppMotion.signature,
            builder: (context, tint, _) => TweenAnimationBuilder<double>(
              tween: Tween<double>(end: target),
              duration: MotionGuard.duration(context, spring.duration),
              curve: spring,
              builder: (context, round, _) => ProfileGenderChipSurface(
                label: label,
                tint: tint,
                round: round,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
