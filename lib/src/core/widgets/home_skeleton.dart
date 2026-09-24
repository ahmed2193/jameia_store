import 'package:flutter/material.dart';

import '../../config/theme/app_spacing.dart';
import '../responsive/app_size.dart';
import 'skeleton_bone.dart';

/// Home-feed skeleton, in the shape the loaded feed takes: the hero banner,
/// the paged category grid, the promo cards and the first product rail.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  static const int _categoryColumns = 4;
  static const int _categoryRows = 3;
  static const int _cards = 3;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.pageMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero carousel.
          const SkeletonBone(height: AppSize.s170, radius: AppRadius.card),
          const SizedBox(height: AppSpacing.s20),
          // "Shop by category" grid.
          const SkeletonBone(width: AppSize.s140, height: AppSize.s16),
          const SizedBox(height: AppSpacing.s12),
          for (var row = 0; row < _categoryRows; row++) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var column = 0; column < _categoryColumns; column++)
                  const Column(
                    children: [
                      SkeletonBone(
                        width: AppSize.s64,
                        height: AppSize.s64,
                        radius: AppRadius.r4,
                      ),
                      SizedBox(height: AppSpacing.s6),
                      SkeletonBone(width: AppSize.s48, height: AppSize.s10),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s12),
          ],
          const SizedBox(height: AppSpacing.s8),
          // Promo cards + the first product rail share this shape.
          const SkeletonBone(width: AppSize.s120, height: AppSize.s16),
          const SizedBox(height: AppSpacing.s12),
          // Three fixed-width bones are wider than a 360dp screen; the
          // surplus clips here instead of overflowing.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              children: [
                for (var card = 0; card < _cards; card++) ...[
                  if (card > 0) const SizedBox(width: AppSpacing.s8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBone(
                        width: AppSize.s110,
                        height: AppSize.s110,
                        radius: AppRadius.card,
                      ),
                      SizedBox(height: AppSpacing.s6),
                      SkeletonBone(width: AppSize.s96, height: AppSize.s12),
                      SizedBox(height: AppSpacing.s4),
                      SkeletonBone(width: AppSize.s64, height: AppSize.s10),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
