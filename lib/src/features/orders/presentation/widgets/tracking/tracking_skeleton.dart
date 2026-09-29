import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/skeleton_bone.dart';
import '../../../../../core/widgets/skeletonized.dart';
import 'tracking_skeleton_row.dart';

/// The order page while its first read is on the way, shaped like what
/// comes: the status panel (time, disc, the four-stage bar, the headline)
/// and the items card — so the page does not jump when it lands. Shimmers
/// (a still fill under reduced motion); not read out.
class TrackingSkeleton extends StatelessWidget {
  const TrackingSkeleton({super.key});

  static const int _rows = 3;
  static const int _stages = 4;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Skeletonized(
        loading: true,
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.brandWash,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(AppRadius.r2),
                ),
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.gutter,
                  AppSpacing.s16,
                  AppSpacing.gutter,
                  AppSpacing.s20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonBone(width: AppSize.s96),
                              SizedBox(height: AppSpacing.s8),
                              SkeletonBone(
                                width: AppSize.s140,
                                height: AppSize.s32,
                              ),
                              SizedBox(height: AppSpacing.s8),
                              SkeletonBone(width: AppSize.s120),
                            ],
                          ),
                        ),
                        SkeletonBone(
                          width: AppSize.s64,
                          height: AppSize.s64,
                          radius: AppRadius.pill,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    Row(
                      children: [
                        for (var i = 0; i < _stages; i++) ...[
                          if (i > 0) const SizedBox(width: AppSpacing.s4),
                          const Expanded(
                            child: SkeletonBone(
                              height: AppSize.s6,
                              radius: AppRadius.pill,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    const SkeletonBone(
                      width: AppSize.s180,
                      height: AppSize.s20,
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    const SkeletonBone(width: AppSize.s220),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.gutter,
                AppSpacing.section,
                AppSpacing.gutter,
                0,
              ),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.all(
                    Radius.circular(AppRadius.media),
                  ),
                  border: Border.fromBorderSide(
                    BorderSide(color: AppColors.divider),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  child: Column(
                    children: [
                      for (var i = 0; i < _rows; i++) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.s16),
                        const TrackingSkeletonRow(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
