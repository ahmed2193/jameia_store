import 'package:flutter/material.dart';

import '../responsive/app_size.dart';
import '../../config/theme/app_spacing.dart';
import 'list_skeleton.dart';
import 'skeleton_bone.dart';

/// Shop-menu skeleton — header bone + a list of product rows.
class ShopMenuSkeleton extends StatelessWidget {
  const ShopMenuSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBone(height: AppSize.s180, radius: 0),
        SizedBox(height: AppSpacing.s12),
        ListSkeleton(count: 5),
      ],
    );
  }
}
