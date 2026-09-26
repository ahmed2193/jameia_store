import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/skeleton_bone.dart';
import '../../../../../core/widgets/skeletonized.dart';

/// A conversation loading: alternating reply / message bubbles that shimmer
/// (solid under reduced motion). Its bones are hidden from screen readers.
class AssistantThreadSkeleton extends StatelessWidget {
  const AssistantThreadSkeleton({super.key});

  static const List<(bool, double)> _bubbles = [
    (false, AppSize.s220),
    (true, AppSize.s160),
    (false, AppSize.s260),
    (false, AppSize.s180),
    (true, AppSize.s120),
  ];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      excludeSemantics: true,
      child: Skeletonized(
        loading: true,
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsetsDirectional.all(AppSpacing.s16),
          children: [
            for (final (mine, width) in _bubbles)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  bottom: AppSpacing.s16,
                ),
                child: Align(
                  alignment: mine
                      ? AlignmentDirectional.centerEnd
                      : AlignmentDirectional.centerStart,
                  child: SkeletonBone(
                    width: width,
                    height: mine ? AppSize.s40 : AppSize.s64,
                    radius: AppRadius.card,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
