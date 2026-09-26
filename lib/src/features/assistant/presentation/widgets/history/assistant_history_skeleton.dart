import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/skeleton_bone.dart';
import '../../../../../core/widgets/skeletonized.dart';

/// History loading: a few title + preview rows that shimmer.
class AssistantHistorySkeleton extends StatelessWidget {
  const AssistantHistorySkeleton({super.key});

  static const int _rows = 6;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      excludeSemantics: true,
      child: Skeletonized(
        loading: true,
        child: ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsetsDirectional.all(AppSpacing.s16),
          itemCount: _rows,
          itemBuilder: (_, _) => const Padding(
            padding: EdgeInsetsDirectional.only(bottom: AppSpacing.s20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBone(width: AppSize.s180, height: AppSize.s16),
                SizedBox(height: AppSpacing.s8),
                SkeletonBone(height: AppSize.s12),
                SizedBox(height: AppSpacing.s6),
                SkeletonBone(width: AppSize.s120, height: AppSize.s12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
