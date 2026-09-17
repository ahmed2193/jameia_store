import 'package:flutter/material.dart';

import '../responsive/app_size.dart';
import '../../config/theme/app_spacing.dart';
import 'skeleton_bone.dart';

/// Shop-menu / product row skeleton (thumbnail + two text lines + price). Matches
/// `ProductRow` so the swap to real content is seamless.
class ProductRowSkeleton extends StatelessWidget {
  const ProductRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBone(
            width: AppSize.s92,
            height: AppSize.s92,
            radius: AppRadius.r4,
          ),
          SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBone(width: AppSize.s160, height: AppSize.s16),
                SizedBox(height: AppSpacing.s8),
                SkeletonBone(width: AppSize.s220, height: AppSize.s12),
                SizedBox(height: AppSpacing.s6),
                SkeletonBone(width: AppSize.s90, height: AppSize.s12),
                SizedBox(height: AppSpacing.s12),
                SkeletonBone(width: AppSize.s70, height: AppSize.s18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
