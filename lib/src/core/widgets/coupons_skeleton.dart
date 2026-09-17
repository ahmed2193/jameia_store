import 'package:flutter/material.dart';

import '../responsive/app_size.dart';
import '../../config/theme/app_spacing.dart';
import 'skeleton_bone.dart';

/// Coupons-list skeleton — ticket-shaped bones.
// (text styles intentionally unused here — skeletons render bones, not type.)
class CouponsSkeleton extends StatelessWidget {
  const CouponsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pageMargin),
      child: Column(
        children: List<Widget>.generate(
          4,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.s12),
            child: SkeletonBone(height: AppSize.s96, radius: AppRadius.r3),
          ),
        ),
      ),
    );
  }
}
