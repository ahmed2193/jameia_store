import 'package:flutter/material.dart';

import '../../config/theme/app_spacing.dart';
import '../responsive/app_size.dart';
import 'skeleton_bone.dart';

/// Home-feed skeleton, in the shape the loaded feed takes: the wide hero
/// banner, a row of storefront tiles and the first product rail.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  static const int _tiles = 5;
  static const int _cards = 3;
  static const double _gutter = AppSpacing.s16;
  static const double _tile = AppSize.s80;
  static const double _tileRadius = AppSize.r14;

  /// Width : height of a home banner.
  static const double _bannerAspectRatio = 2.35;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: _gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero banner.
          const AspectRatio(
            aspectRatio: _bannerAspectRatio,
            child: SkeletonBone(radius: _tileRadius),
          ),
          const SizedBox(height: AppSpacing.s20),
          // "Shop by category" tiles. The row is wider than a phone; the
          // surplus clips here instead of overflowing.
          const SkeletonBone(width: AppSize.s140, height: AppSize.s16),
          const SizedBox(height: AppSpacing.s12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              children: [
                for (var tile = 0; tile < _tiles; tile++) ...[
                  if (tile > 0) const SizedBox(width: AppSpacing.s10),
                  const Column(
                    children: [
                      SkeletonBone(
                        width: _tile,
                        height: _tile,
                        radius: _tileRadius,
                      ),
                      SizedBox(height: AppSpacing.s6),
                      SkeletonBone(width: AppSize.s56, height: AppSize.s10),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s20),
          // The first product rail.
          const SkeletonBone(width: AppSize.s120, height: AppSize.s16),
          const SizedBox(height: AppSpacing.s12),
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
                        width: AppSize.s130,
                        height: AppSize.s130,
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
