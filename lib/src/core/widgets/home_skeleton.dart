import 'package:flutter/material.dart';

import '../responsive/app_size.dart';
import '../../config/theme/app_spacing.dart';
import 'skeleton_bone.dart';

/// Home-feed skeleton: a hero banner bone + a row of king-kong circles + a couple
/// of shop-card bones.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pageMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBone(height: AppSize.s120, radius: AppRadius.r3),
          const SizedBox(height: AppSpacing.s16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List<Widget>.generate(
              5,
              (_) => const Column(
                children: [
                  SkeletonBone(
                    width: AppSize.s48,
                    height: AppSize.s48,
                    radius: AppRadius.r2,
                  ),
                  SizedBox(height: AppSpacing.s6),
                  SkeletonBone(width: AppSize.s40, height: AppSize.s10),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s20),
          const SkeletonBone(height: AppSize.s150, radius: AppRadius.r4),
          const SizedBox(height: AppSpacing.s8),
          const SkeletonBone(width: AppSize.s180, height: AppSize.s16),
          const SizedBox(height: AppSpacing.s6),
          const SkeletonBone(width: AppSize.s120, height: AppSize.s12),
        ],
      ),
    );
  }
}
