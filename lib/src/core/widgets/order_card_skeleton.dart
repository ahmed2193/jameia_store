import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../responsive/app_size.dart';
import 'skeleton_bone.dart';

/// One order card as bones, in the card's own frame (white, hairline, 16 dp
/// radius): the status tag, the order number, the date, a preview line, the
/// item count against the total, and an action pill — so the real card lands
/// where its skeleton was.
class OrderCardSkeleton extends StatelessWidget {
  const OrderCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.fromBorderSide(BorderSide(color: AppColors.divider)),
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.media)),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SkeletonBone(
              width: AppSize.s80,
              height: AppSize.s20,
              radius: AppRadius.chip,
            ),
            SizedBox(height: AppSpacing.s12),
            SkeletonBone(width: AppSize.s160, height: AppSize.s16),
            SizedBox(height: AppSpacing.s8),
            SkeletonBone(width: AppSize.s120, height: AppSize.s14),
            SizedBox(height: AppSpacing.s8),
            SkeletonBone(width: AppSize.s220, height: AppSize.s14),
            SizedBox(height: AppSpacing.s16),
            Row(
              children: [
                SkeletonBone(width: AppSize.s72, height: AppSize.s14),
                Spacer(),
                SkeletonBone(width: AppSize.s80, height: AppSize.s16),
              ],
            ),
            SizedBox(height: AppSpacing.s16),
            SkeletonBone(
              width: double.infinity,
              height: AppSize.s44,
              radius: AppRadius.pill,
            ),
          ],
        ),
      ),
    );
  }
}
