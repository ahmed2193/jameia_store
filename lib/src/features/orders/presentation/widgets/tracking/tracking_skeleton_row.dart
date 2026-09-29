import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/skeleton_bone.dart';

/// One item row of [TrackingSkeleton]: the photo, two text lines, the price.
class TrackingSkeletonRow extends StatelessWidget {
  const TrackingSkeletonRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SkeletonBone(width: AppSize.s44, height: AppSize.s44),
        SizedBox(width: AppSpacing.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBone(width: AppSize.s160),
              SizedBox(height: AppSpacing.s8),
              SkeletonBone(width: AppSize.s96),
            ],
          ),
        ),
        SizedBox(width: AppSpacing.s12),
        SkeletonBone(width: AppSize.s56),
      ],
    );
  }
}
